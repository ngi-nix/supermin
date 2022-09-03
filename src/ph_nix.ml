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

open Unix
open Printf

open Utils
open Package_handler

let have_exe exe_name =
  Sys.command (sprintf "command -v %s >/dev/null 2>&1" exe_name) == 0

let nix_detect () =
  let b = have_exe "nix-instantiate" && have_exe "nix-store"
  in (b, if b then None else Some "command -v could not find one of [nix-instantiate, nix-store].")

let settings = ref no_settings

let nix_init s = settings := s

type pac_t = {
  name : string;
  path : string;
}

let pac_of_pkg, pkg_of_pac = get_memo_functions ()

let nix_instantiate name = 
  let cmd = sprintf "nix-instantiate '<nixpkgs>' -A %s" (quote name)
  in
    if !settings.debug >= 2 then printf "%s" cmd; (*TODO shouldnt this be <=?*)
    let drv =List.hd( run_command_get_lines cmd)
    in drv

let nix_realise path =
  let cmd = sprintf "nix-store --realise %s" (quote path)
  in
    if !settings.debug >= 2 then printf "%s" cmd; (*TODO shouldnt this be <=?*)
    let path = List.hd( run_command_get_lines cmd)
    in path

(*TODO error handling*)
let nix_package_of_string str =
  let drv = nix_instantiate str in
  let path = nix_realise drv in
  Some (pkg_of_pac { name = str; path = path; })

let clean_path path =
  (* Remove trailing / from directory names. *)
  let len = String.length path
  in
    if len >= 2 && path.[len-1] = '/' then
      String.sub path 0 (len-1)
    else
      path 

let path_to_file path =
  (*TODO what is this supposed to do?*)
  let config =
    try string_prefix "/etc/" path && (lstat path).st_kind = S_REG
    with Unix_error _ -> false
  in
    { ft_path = path; ft_source_path = path; ft_config = config }

let nix_find_files pac =
  let cmd = sprintf "nix-store -qR %s | xargs find" pac.path
  in
    if !settings.debug >= 2 then printf "%s" cmd; (*TODO shouldnt this be <=?*)
    let lines = run_command_get_lines cmd
    in List.map (fun path -> path_to_file (clean_path path)) lines 
  

let nix_get_files pkgs =
  List.concat (List.map (fun x -> nix_find_files (pac_of_pkg x)) (PackageSet.elements pkgs))

let () =
  let ph = {
    ph_detect = nix_detect;
(*    ph_init = (fun settings -> failwith "unimplemented nix ph_init");*)
    ph_init = nix_init;
    ph_fini = (fun () -> ());
    ph_package_of_string = nix_package_of_string;
    ph_package_to_string = (fun pkg -> (pac_of_pkg pkg).name);
    ph_package_name = (fun pkg -> (pac_of_pkg pkg).name);
    ph_get_package_database_mtime = ( fun () -> failwith "unimplemented nix ph_get_package_database_mtime");
    ph_get_requires = PHGetAllRequires (fun pkgs -> pkgs);
    ph_get_files = PHGetAllFiles nix_get_files;
    ph_download_package = PHDownloadAllPackages ( fun pkgs dir -> failwith "unimplemented nix ph_download_package");
  } in
  register_package_handler "any_system" "nix" ph
