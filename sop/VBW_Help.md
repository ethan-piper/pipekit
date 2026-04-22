VBW Help — v1.35.0

Lifecycle — The Main Loop
    /vbw:discuss [N]         Start/continue phase discussion before planning
    /vbw:init                Set up environment, scaffold .vbw-planning
    /vbw:vibe [intent/flags] The one command — routes to any lifecycle mode
                             (plan, execute, verify, discuss, archive, etc.)

Monitoring — Trust But Verify
    /vbw:status              Project progress dashboard

    Note: /vbw:qa and /vbw:verify were absorbed into /vbw:vibe --verify
    in v1.35.0. They still exist as hidden commands but are no longer
    part of the public help surface.

Supporting — The Safety Net
    /vbw:compress <file>     Caveman-compress natural language to save tokens
    /vbw:config              View/modify VBW configuration
    /vbw:debug <desc>        Investigate bugs with scientific method
                             (now self-contained — absorbs QA + UAT inline)
    /vbw:doctor              Health checks on installation
    /vbw:fix <desc>          Quick fix with commit discipline
    /vbw:help [cmd]          This help screen
    /vbw:list-todos          List pending backlog items with action hints
    /vbw:pause               Save session notes
    /vbw:profile [name]      Switch work profiles
    /vbw:report [desc]       Collect diagnostics, classify, auto-file GH issue
    /vbw:resume              Restore project context
    /vbw:skills              Browse/install community skills
    /vbw:teach               Manage project conventions
    /vbw:todo <desc>         Add to persistent backlog

Advanced
    /vbw:map                 Analyze codebase with Scout agents
    /vbw:research <topic>    Standalone research via Scout (with staleness tracking)
    /vbw:uninstall           Remove all VBW traces
    /vbw:update              Update to latest version
    /vbw:whats-new           View changelog

Getting Started: /vbw:init → /vbw:vibe → /vbw:vibe --archive

--

Known quirks (VBW v1.35.0)

    .vbw-planning/.agent-pids (and siblings) leak into git status
        Cause: planning-git.sh sync-ignore only writes the nested
               .vbw-planning/.gitignore when planning_tracking=commit.
               In manual mode (the default), the transient-files
               gitignore is never written.
        Workaround: flip mode to commit then back to manual:
               /vbw:config planning_tracking commit
               /vbw:config planning_tracking manual
               The nested .gitignore persists across the flip.
               Commit .vbw-planning/.gitignore once; you're done forever.
        Upstream: filed via /vbw:report against
                  yidakee/vibe-better-with-claude-code-vbw.

