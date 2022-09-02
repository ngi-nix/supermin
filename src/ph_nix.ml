(* supermin 5
 * Copyright (C) 2009-2014 Red Hat Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *)

open Package_handler

let nix_detect () =
  Config.nix_instantiate <> "no" && Config.nix_store <> "no"

let () =
  let ph = {
    ph_detect = nix_detect;
    ph_init = (fun settings -> failwith "unimplemented nix ph_init");
    ph_fini = (fun () -> ());
    ph_package_of_string = (fun pkgname -> failwith "unimplemented nix ph_package_of_string");
    ph_package_to_string = (fun pkg -> failwith "unimplemented nix ph_package_to_string");
    ph_package_name = ( fun pkg -> failwith "unimplemented nix ph_package_name");
    ph_get_package_database_mtime = ( fun () -> failwith "unimplemented nix ph_get_package_database_mtime");
    ph_get_requires = PHGetAllRequires ( fun pkgs -> failwith "unimplemented nix ph_get_requires");
    ph_get_files = PHGetAllFiles ( fun pkgs -> failwith "unimplemented nix ph_get_files");
    ph_download_package = PHDownloadAllPackages ( fun pkgs dir -> failwith "unimplemented nix ph_download_package");
  } in
  register_package_handler "any_system" "nix" ph
