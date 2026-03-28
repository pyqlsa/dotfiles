// sets a "fun name" for a tailnet;
//
// NOTICE: when a new batch is requested, tokens from the previous batch are
// invalidated by tailscale; attempting to set a name from a previous batch
// will fail;
//
// all credit goes to:
// https://yousefamar.com/memo/articles/hacks/tailnet-name/

// cookie from logged in browser session
const cookie = "<your-cookie>";

// optional
const useragent = "";

// set these based on output from gettsname
const { tcd, token } = {
  tcd: '<some-name>.ts.net',
  token: '<some-name>.ts.net/...'
}

fetch("https://login.tailscale.com/admin/api/tcd", {
  "headers": {
    "Accept": "application/json, text/plain, */*",
    "Accept-Language": "en-US,en;q=0.9",
    "Accept-Encoding": "gzip, deflate, br, zstd",
    "Cache-Control": "no-cache",
    "content-type": "application/json",
    "Pragma": "no-cache",
    "Sec-Fetch-Dest": "empty",
    "Sec-Fetch-Mode": "cors",
    "Sec-Fetch-Site": "same-origin",
    "sec-gpc": "1",
    "Cookie": cookie,
    "Referer": "https://login.tailscale.com/admin/dns",
    "Priority": "u=0",
    "TE": "trailers",
    "User-Agent": useragent
  },
  "body": `{"tcd":"${tcd}","token":"${token}"}`,
  "method": "POST"
}).then(response => response.json()).then(data => console.log(data)).catch(error => console.error('Error:', error));


