{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.bash = {
      enable = true;

      logoutExtra = ''
        clear-console
      '';
    };

    nmt.script = ''
      assertFileExists home-files/.bash_logout
      assertFileContent \
        home-files/.bash_logout \
        ${
          pkgs.writeShellScript "logout-expected" ''
            clear-console
          ''
        }
    '';
  };
}
