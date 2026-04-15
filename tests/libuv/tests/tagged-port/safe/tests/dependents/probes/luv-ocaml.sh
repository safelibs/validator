#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
. "${script_dir}/../common.sh"

main() {
  libuv_note "Testing Luv for OCaml"
  cat >/tmp/luv_timer.ml <<'ML'
let () =
  let fired = ref false in
  match Luv.Timer.init () with
  | Error err -> failwith (Luv.Error.strerror err)
  | Ok timer ->
      begin
        match Luv.Timer.start timer 10 (fun () ->
          fired := true;
          ignore (Luv.Timer.stop timer);
          Luv.Handle.close timer ignore
        ) with
        | Error err -> failwith (Luv.Error.strerror err)
        | Ok () -> ()
      end;
      ignore (Luv.Loop.run ());
      if not !fired then failwith "timer did not fire"
ML
  ocamlfind ocamlopt -thread -package threads,luv -linkpkg \
    -o /tmp/luv_timer /tmp/luv_timer.ml
  /tmp/luv_timer
}

main "$@"
