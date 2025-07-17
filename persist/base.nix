{ lib, ... }:
rec {
  persistentOption =
    with lib;
    with lib.types;
    mkOption {
      description = "submodule example";
      type = attrsOf (submodule {
        options = {
          prefix = mkOption {
            default = "/persistent/";
            type = strMatching "^/([[:alnum:]_]+/)?$";
          };
          contents = mkOption {
            default = [ ];
            type = listOf (
              coercedTo str
                (s: {
                  path = s;
                  secret = false;
                })
                (submodule {
                  options = {
                    path = mkOption {
                      type = str;
                      description = "Path to persist.";
                    };
                    secret = mkOption {
                      type = bool;
                      default = false;
                      description = "If true, uses restricted permissions.";
                    };
                  };
                })
            );
          };
        };
      });
    };

  isDirectory = lib.hasSuffix "/";
  isSystem = lib.hasPrefix "/";
  not = f: a: !(f a);
  stripTrailing = p: lib.substring 0 (builtins.stringLength p - 1) p;
  filter2 =
    f: g: c:
    builtins.filter f (builtins.filter g c);
  normalize =
    entry:
    if builtins.isString entry then
      {
        path = entry;
        secret = false;
      }
    else
      entry;

  parseUserDirectories = paths: map stripTrailing (filter2 (not isSystem) isDirectory paths);
  parseUserFiles = paths: filter2 (not isSystem) (not isDirectory) paths;
  parseSystemDirectories = paths: map stripTrailing (filter2 isSystem isDirectory paths);
  parseSystemFiles = paths: filter2 isSystem (not isDirectory) paths;

  dirsAndFiles =
    isSystem: contents:
    let
      normalized = map normalize contents;
      paths = map (e: e.path) normalized;
      secrets = lib.listToAttrs (
        map (e: {
          name = e.path;
          value = e.secret;
        }) normalized
      );
      dirPaths = if isSystem then parseSystemDirectories else parseUserDirectories;
      filePaths = if isSystem then parseSystemFiles else parseUserFiles;

      formatDir =
        path:
        if secrets.${path} or false then
          {
            directory = path;
            mode = "0700";
          }
        else
          path;
      formatFile =
        path:
        if secrets.${path} or false then
          {
            file = path;
            parentDirectory = {
              mode = "0700";
            };
          }
        else
          path;
    in
    {
      directories = map formatDir (dirPaths paths);
      files = map formatFile (filePaths paths);
    };
}
