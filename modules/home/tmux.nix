{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    mouse = true;
    terminal = "screen-256color";
    keyMode = "vi";
    escapeTime = 10;
    historyLimit = 102400;
    baseIndex = 1;
    clock24 = true;

    plugins = with pkgs.tmuxPlugins; [
      resurrect
      continuum
      prefix-highlight
    ];

    extraConfig = ''
      # Default shell
      set -g default-shell "$SHELL"

      # Set windows and pane index to base 1
      setw -g pane-base-index 1

      # Re-number windows when creating/closing new windows
      set -g renumber-windows on

      # Use emacs key bindings in status line
      set-option -g status-keys emacs

      # Fix ESC delay in vim
      set -g escape-time 10

      # Prefix to C-a
      unbind C-b
      set -g prefix C-a

      # Copy-mode (macOS clipboard)
      unbind-key -T copy-mode-vi v
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-pipe "pbcopy"
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"
      bind-key -T copy-mode-vi Escape send-keys -X cancel

      # Send command on double press
      unbind-key -T root C-l
      bind-key -T root C-l send-keys C-l

      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

      # Split panes and remember current path
      bind '\\' split-window -h -c '#{pane_current_path}'
      bind - split-window -v -c '#{pane_current_path}'

      # New windows keep current path
      bind c new-window -c '#{pane_current_path}'

      # Break pane into new window and keep focus on current window
      bind b break-pane -d

      # Pane navigation
      bind-key Up select-pane -U
      bind-key Down select-pane -D
      bind-key Left select-pane -L
      bind-key Right select-pane -R

      # Status bar theme
      set -g status-style "bg=#282828,fg=#ebdbb2"
      set -g status-left "#[fg=#282828,bg=#d65d0e] #S #[fg=#d65d0e,bg=#282828] "
      set -g status-right "#[fg=#928374]#{prefix_highlight} %H:%M "
      set -g window-status-format "#[fg=#928374] #I:#W "
      set -g window-status-current-format "#[fg=#d65d0e,bold] #I:#W#{?window_zoomed_flag, ⇪ , } "
      set -g window-status-separator " "

      set -g pane-border-style "fg=#282828"
      set -g pane-active-border-style "fg=#d65d0e"
      set -g message-style "bg=#282828,fg=#ebdbb2"
      set -g message-command-style "bg=#282828,fg=#ebdbb2"
      set -g mode-style "bg=#d65d0e,fg=#282828"
      set -g clock-mode-colour "#d65d0e"

      # Focus events and passthrough
      set -g focus-events on
      set -g allow-passthrough on

      # Ensure tmux knows how to handle terminal env
      set -ga update-environment TERM
      set -ga update-environment TERM_PROGRAM

      # Activity indicator
      set -g window-status-activity-style "fg=#fb4934"

      # Continuum settings
      set -g @continuum-save-interval '15'
      set -g @continuum-restore 'on'

      # Prefix highlight settings
      set -g @prefix_highlight_show_copy_mode 'on'
      set -g @prefix_highlight_copy_mode_attr 'fg=#ebdbb2,bg=#d65d0e'
    '';
  };
}
