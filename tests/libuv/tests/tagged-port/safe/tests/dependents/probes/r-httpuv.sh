#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../common.sh
. "${script_dir}/../common.sh"

main() {
  libuv_note "Testing R httpuv package"
  Rscript - <<'RS'
port <- 8123L
outfile <- tempfile()
app <- list(call = function(req) {
  list(status = 200L, headers = list("Content-Type" = "text/plain"), body = "ok")
})
server <- httpuv::startServer("127.0.0.1", port, app)
on.exit({ try(server$stop(), silent = TRUE) }, add = TRUE)
system2("curl", c("-fsS", sprintf("http://127.0.0.1:%d/", port), "-o", outfile), wait = FALSE)
deadline <- Sys.time() + 5
while (Sys.time() < deadline && (!file.exists(outfile) || file.info(outfile)$size == 0)) {
  httpuv::service(100)
}
stopifnot(file.exists(outfile))
stopifnot(identical(readLines(outfile, warn = FALSE), "ok"))
RS
}

main "$@"
