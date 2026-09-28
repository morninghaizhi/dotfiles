#!/usr/bin/env python3
"""WezTerm のウインドウ/タブ/ペイン構成と、各ペインの Claude Code セッションを
保存・復元するスクリプト。

  wz-session.py save              現在の構成を JSON に保存
  wz-session.py restore           保存した構成を復元（claude --resume 付き）
  wz-session.py show              保存内容を一覧表示
  wz-session.py restore --dry-run 実行する wezterm コマンドを表示するだけ
"""
import argparse
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

STATE = Path.home() / ".config/wezterm/session-restore/last.json"
CLAUDE_SESSIONS = Path.home() / ".claude/sessions"
SHELLS = {"zsh", "-zsh", "bash", "-bash", "sh", "-sh", "fish", "-fish", "login"}


def sh(args):
    return subprocess.run(args, capture_output=True, text=True, check=True).stdout


# ---------------------------------------------------------------- save
def claude_by_tty():
    """tty -> {"session_id", "cwd"} を作る。

    ~/.claude/sessions/<PID>.json に sessionId と cwd が入っているので、
    ps で得た tty→PID と突き合わせる。"""
    out = {}
    ps = sh(["ps", "-eo", "pid=,tty=,command="])
    pid_by_tty = {}
    for line in ps.splitlines():
        m = re.match(r"\s*(\d+)\s+(\S+)\s+(.*)$", line)
        if not m:
            continue
        pid, tty, cmd = m.group(1), m.group(2), m.group(3).strip()
        if tty.startswith("ttys") and os.path.basename(cmd.split()[0]) == "claude":
            pid_by_tty.setdefault("/dev/" + tty, pid)
    for tty, pid in pid_by_tty.items():
        f = CLAUDE_SESSIONS / f"{pid}.json"
        if not f.exists():
            continue
        try:
            d = json.loads(f.read_text())
        except json.JSONDecodeError:
            continue
        if d.get("pid") != int(pid) or not d.get("sessionId"):
            continue
        out[tty] = {"session_id": d["sessionId"], "cwd": d.get("cwd", ""),
                    "name": d.get("name", "")}
    return out


def foreground_by_tty(tty):
    """tty で動いている前面コマンド（シェル以外の最上位）を返す。"""
    try:
        ps = sh(["ps", "-t", os.path.basename(tty), "-o", "pid=,ppid=,command="])
    except subprocess.CalledProcessError:
        return None
    procs = []
    for line in ps.splitlines():
        m = re.match(r"\s*(\d+)\s+(\d+)\s+(.*)$", line)
        if m:
            procs.append((m.group(1), m.group(2), m.group(3).strip()))
    pids = {p for p, _, _ in procs}
    for pid, ppid, cmd in procs:
        argv0 = os.path.basename(cmd.split()[0])
        if argv0 in SHELLS:
            continue
        # 同じ tty 上の非シェルの子孫は除外（最上位だけ拾う）
        if ppid in pids and any(
            p == ppid and os.path.basename(c.split()[0]) not in SHELLS
            for p, _, c in procs
        ):
            continue
        return cmd
    return None


def do_save(args):
    panes = json.loads(sh(["wezterm", "cli", "list", "--format", "json"]))
    cmap = claude_by_tty()
    saved = []
    for p in panes:
        tty = p.get("tty_name") or ""
        cwd = p["cwd"].replace("file://", "").rstrip("/") or str(Path.home())
        entry = {
            "window_id": p["window_id"], "tab_id": p["tab_id"], "pane_id": p["pane_id"],
            "left": p["left_col"], "top": p["top_row"],
            "cols": p["size"]["cols"], "rows": p["size"]["rows"],
            "title": p["title"], "cwd": cwd, "kind": "shell", "cmd": None, "note": None,
        }
        fg = foreground_by_tty(tty)
        if tty in cmap:
            c = cmap[tty]
            entry["kind"] = "claude"
            entry["cmd"] = f"claude --resume {c['session_id']}"
            entry["cwd"] = c["cwd"] or entry["cwd"]
            entry["session_id"] = c["session_id"]
        elif fg and os.path.basename(fg.split()[0]) in ("nvim", "vim"):
            entry["kind"] = "editor"
            entry["cmd"] = fg
        elif fg:
            # 開発サーバ等は自動実行しない（意図しない副作用を避ける）
            entry["note"] = fg
        saved.append(entry)

    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(json.dumps(
        {"saved_at": time.time(), "panes": saved}, ensure_ascii=False, indent=2))
    n_claude = sum(1 for e in saved if e["kind"] == "claude")
    tabs = len({(e["window_id"], e["tab_id"]) for e in saved})
    wins = len({e["window_id"] for e in saved})
    print(f"保存: {wins} ウインドウ / {tabs} タブ / {len(saved)} ペイン "
          f"(claude {n_claude} 個) -> {STATE}")


# ---------------------------------------------------------------- restore
def split_group(panes):
    """ペインの矩形集合を guillotine 分割し ('v'|'h', 手前, 奥) を返す。"""
    for axis, lo, size in (("v", "left", "cols"), ("h", "top", "rows")):
        edges = sorted({p[lo] for p in panes})[1:]
        for e in edges:
            a = [p for p in panes if p[lo] < e]
            b = [p for p in panes if p[lo] >= e]
            if a and b and all(p[lo] + p[size] <= e for p in a):
                return axis, a, b
    return None, None, None


def span(panes, axis):
    """分割方向に沿ったペイン群の幅（列数 or 行数）。"""
    lo, size = ("left", "cols") if axis == "v" else ("top", "rows")
    return max(p[lo] + p[size] for p in panes) - min(p[lo] for p in panes)


def build(panes, target, plan):
    """target のペインに panes 群を再構成する計画を plan に積む。"""
    if len(panes) == 1:
        panes[0]["_dest"] = target
        return
    axis, a, b = split_group(panes)
    if axis is None:  # 分割不能（極端なレイアウト）→ 縦に並べて妥協
        axis, a, b = "v", panes[:1], panes[1:]
    total = span(a, axis) + span(b, axis) + 1
    pct = max(5, min(95, round(span(b, axis) * 100 / total)))
    new = {"op": "split", "from": target, "dir": "--right" if axis == "v" else "--bottom",
           "percent": pct, "cwd": b[0]["cwd"]}
    plan.append(new)
    build(a, target, plan)
    build(b, new, plan)


def do_restore(args):
    if not STATE.exists():
        sys.exit(f"保存データがありません: {STATE}  先に `wz-session.py save` を実行")
    data = json.loads(STATE.read_text())
    panes = data["panes"]
    origin = os.environ.get("WEZTERM_PANE")

    windows = {}
    for p in panes:
        windows.setdefault(p["window_id"], {}).setdefault(p["tab_id"], []).append(p)

    plan = []
    for wi, (win, tabs) in enumerate(sorted(windows.items())):
        for ti, (tab, group) in enumerate(sorted(tabs.items())):
            group.sort(key=lambda p: (p["top"], p["left"]))
            root = {"op": "spawn", "cwd": group[0]["cwd"],
                    "new_window": (wi > 0 or not args.here), "window_ref": win}
            plan.append(root)
            build(group, root, plan)

    # 実行
    for step in plan:
        if step["op"] == "spawn":
            cmd = ["wezterm", "cli", "spawn", "--cwd", step["cwd"]]
            if step["window_ref"] in _win_ids:
                # 同じウインドウの 2 つめ以降のタブ
                cmd += ["--window-id", str(_win_ids[step["window_ref"]])]
            elif step["new_window"]:
                cmd.append("--new-window")
        else:
            cmd = ["wezterm", "cli", "split-pane", "--pane-id", str(step["from"]["_pane"]),
                   step["dir"], "--percent", str(step["percent"]), "--cwd", step["cwd"]]
        if args.dry_run:
            print(" ".join(cmd))
            step["_pane"] = f"<pane{plan.index(step)}>"
            if step["op"] == "spawn":
                _win_ids.setdefault(step["window_ref"], f"<win{step['window_ref']}>")
            continue
        pane_id = sh(cmd).strip()
        step["_pane"] = pane_id
        if step["op"] == "spawn" and step["window_ref"] not in _win_ids:
            info = json.loads(sh(["wezterm", "cli", "list", "--format", "json"]))
            for p in info:
                if str(p["pane_id"]) == pane_id:
                    _win_ids[step["window_ref"]] = p["window_id"]
        time.sleep(0.15)

    # コマンド投入（シェルの起動を待ってから）
    if not args.dry_run:
        time.sleep(1.0)
    for p in panes:
        dest = p.get("_dest")
        if not dest or not p.get("cmd"):
            continue
        pane_id = dest["_pane"]
        text = p["cmd"] + "\n"
        if args.dry_run:
            print(f"wezterm cli send-text --pane-id {pane_id} --no-paste {text!r}")
        else:
            subprocess.run(["wezterm", "cli", "send-text", "--pane-id", str(pane_id),
                            "--no-paste", text], check=True)
            time.sleep(0.3)

    notes = [p for p in panes if p.get("note")]
    if notes:
        print("\n自動実行しなかったコマンド（必要なら手動で）:")
        for p in notes:
            print(f"  {p['cwd']}: {p['note']}")
    if origin and not args.dry_run:
        print(f"\n復元元のペイン {origin} は不要なら閉じてください。")


_win_ids = {}


def do_show(args):
    if not STATE.exists():
        sys.exit(f"保存データがありません: {STATE}")
    data = json.loads(STATE.read_text())
    print(f"saved_at: {time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(data['saved_at']))}")
    for p in data["panes"]:
        mark = {"claude": "C", "editor": "E", "shell": "-"}[p["kind"]]
        print(f"  [{mark}] win{p['window_id']} tab{p['tab_id']:>3} "
              f"{p['cwd'].replace(str(Path.home()), '~'):<45} "
              f"{p.get('cmd') or p.get('note') or ''}")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("save").set_defaults(func=do_save)
    sub.add_parser("show").set_defaults(func=do_show)
    r = sub.add_parser("restore")
    r.add_argument("--dry-run", action="store_true", help="実行せずコマンドを表示")
    r.add_argument("--here", action="store_true",
                   help="最初のタブを現在のウインドウに作る")
    r.set_defaults(func=do_restore)
    args = ap.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
