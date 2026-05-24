{
  pkgs,
  githubUsername,
  githubEmail,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # GitHub CLI - used for auth, PR/issue management, and HTTPS credential delegation
    gh
    # Terminal UI for Git - visual branch/diff/commit management
    lazygit
  ];
  programs.git = {
    enable = true;
    config = {
      init = {
        defaultBranch = "main";
      };
      user = {
        name = "${githubUsername}";
        email = "${githubEmail}";
      };
      # Delegate GitHub HTTPS credential handling to the gh CLI (runs `gh auth git-credential`)
      credential = {
        "https://github.com".helper = "!gh auth git-credential";
      };
    };
  };
}

