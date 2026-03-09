{
  config,
  pkgs,
  lib,
  ...
}:
let
  purePkgs = pkgs.pure-unstable; # to avoid build ungoogled-chromium because it uses too much RAM

  createDevtools = { package, env }:{
    command = lib.getExe package;
    args = [ ];
    env = env;
  };
  devtoolsArgsMinimal = {
    package = pkgs.mcp-server-devtools;
    env =  {
      ENABLE_ADDITIONAL_TOOLS = lib.concatStringsSep "," [
        "memory"
        "sequential-thinking" # instead of think
        "security"
        "security_override"
      ];
      DISABLED_FUNCTIONS = lib.concatStringsSep "," [
        "calculator"
        "find_long_files"
        "devtools_help"
        "think"
      ];
    };
  };
  devtoolsArgsLocalWebSearch = {
    package = pkgs.mcp-server-devtools;
    env =  devtoolsArgsMinimal.env // {
      # TODO: refactor to support the changing of these URLs without needing to override the whole package
      SEARXNG_BASE_URL = lib.concatStringsSep "," [
        "http://localhost:16060"
      ];
    };
  };
  devtoolsArgsAll = {
    package = pkgs.mcp-server-devtools.withPackages [
      # TODO: enable after NixOS 26.05
      # # For docling override
      # (purePkgs.python3Packages.toPythonApplication (purePkgs.python3Packages.docling.override { # for process_document tool
      #   docling-parse = purePkgs.python3Packages.docling-parse.overrideAttrs (old: {
      #     meta.broken = false; # TODO: remove after NixOS 26.05
      #   });
      # }))
    ];
    env =  {
      # TODO: refactor to support the changing of these URLs without needing to override the whole package
      SEARXNG_BASE_URL = lib.concatStringsSep "," [
        "http://localhost:16060"
      ];
      ENABLE_ADDITIONAL_TOOLS = devtoolsArgsMinimal.env.ENABLE_ADDITIONAL_TOOLS + "," + (lib.concatStringsSep "," [
        "github"
        "pdf"
        # TODO: enable after NixOS 26.05
        # "process_document"
        # TODO: check fixing of "Error: tool parameters array type must have items" in github copilot
        # "excel"
      ]);
      DISABLED_FUNCTIONS = devtoolsArgsMinimal.env.DISABLED_FUNCTIONS;
    };
  };
in
{
  arxiv = {
    command = lib.getExe pkgs.mcp-server-arxiv;
    args = [ ];
  };
  devtools-minimal = createDevtools devtoolsArgsMinimal;
  devtools-local-web-search = createDevtools devtoolsArgsLocalWebSearch;
  devtools-all = createDevtools devtoolsArgsAll;
  git = {
    command = lib.getExe pkgs.mcp-server-git;
    args = [ ];
  };
  nixos = {
    command = lib.getExe purePkgs.mcp-nixos;
    args = [ ];
  };
  excel = {
    command = lib.getExe pkgs.mcp-server-excel;
    args = [ "stdio" ];
  };
  playwright = {
    # Use ungoogled-chromium
    command = lib.getExe purePkgs.playwright-mcp;
    args = [
      "--executable-path"
      "${lib.getExe purePkgs.ungoogled-chromium}"
    ];
  };
  "pdf-reader" = {
    command = lib.getExe pkgs.mcp-server-pdf-reader;
    args = [ ];
  };
  markitdown = {
    command = lib.getExe purePkgs.markitdown-mcp;
    args = [ ];
  };
  ocr = {
    command = lib.getExe pkgs.mcp-server-ocr;
    args = [ ];
  };
  quickchart = {
    command = lib.getExe pkgs.mcp-server-quickchart;
    args = [ ];
  };
  jetbrains = {
    command = lib.getExe pkgs.mcp-server-jetbrains;
    args = [ ];
  };
  serena = {
    command = lib.getExe pkgs.serena;
    args = [
      "start-mcp-server"
      "--enable-web-dashboard"
      "false"
    ];
  };
  atlassian = {
    # TODO: may be able to replace to "url"
    command = lib.getExe pkgs.mcp-server-remote;
    args = [
      "https://mcp.atlassian.com/v1/sse"
    ];
  };
  azure-devops = {
    command = lib.getExe pkgs.mcp-server-azure-devops;
    args = [
      "!! input your organization manually !!!"
    ];
  };
  spec-workflow = {
    command = lib.getExe pkgs.mcp-server-spec-workflow;
    args = [
      "/path/to/your/project"
      "--AutoStartDashboard"
    ];
  };
  lsp = {
    command = lib.getExe purePkgs.mcp-language-server;
    args = [
      "!! input your project path manually !!!"
    ];
  };
  mysql = {
    command = lib.getExe pkgs.mcp-server-mysql;
    args = [ ];
    env = {
      MYSQL_HOST = "127.0.0.1";
      MYSQL_PORT = "3306";
      MYSQL_USER = "root";
      MYSQL_PASS = "your_password";
      MYSQL_DB = "your_database";
      ALLOW_INSERT_OPERATION = "false";
      ALLOW_UPDATE_OPERATION = "false";
      ALLOW_DELETE_OPERATION = "false";
    };
  };
  wireshark = {
    command = lib.getExe pkgs.mcp-server-wireshark;
    args = [ ];
  };
  textlint = lib.optionalAttrs config.my.home.documentation.enable {
    command = "${config.my.home.documentation.executablePath}/bin/textlint";
    args = [
      "--mcp"
    ];
  };
  yfinance = {
    command = lib.getExe pkgs.mcp-server-yfinance;
    args = [ ];
  };
  investor-agent = {
    command = lib.getExe pkgs.mcp-server-investor-agent;
    args = [ ];
  };
  wakapi = {
    env = {
      WAKAPI_URL = "http://localhost:3000";
      WAKAPI_API_KEY = "your-api-key";
    };
    command = lib.getExe (builtins.getFlake "github:impure0xntk/mcp-wakapi/85c2ac01e4926b00d3a709538d492cfbf813e1e1")
    .packages.x86_64-linux.default;
    args = [ ];
  };
  vscode = {
    # see the bottom of this file
    command = lib.getExe pkgs.mcp-server-remote;
    args = [
      "http://localhost:13001/mcp"
    ];
  };
}
