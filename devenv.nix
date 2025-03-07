{ pkgs, lib, config, inputs, ... }:

{
  packages = [ 
    pkgs.git
    pkgs.jq
    pkgs.yq
    pkgs.pre-commit
    pkgs.kubectl
    pkgs.awscli
    pkgs.gnumake
  ];

  languages.javascript = {
    enable = true;
    package = pkgs.nodejs_20; # Replace with your desired version
  };
  languages.typescript.enable = true;
  languages.javascript.yarn.enable = true;
  languages.terraform.enable = true;
}
