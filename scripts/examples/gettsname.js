// gets randomly generated "fun names" for a tailnet;
//
// stops when a suggested name matches filters below;
//
// NOTICE: when a new batch is requested, tokens from the previous batch are
// invalidated by tailscale; attempting to set a name from a previous batch
// will fail;
//
// all credit goes to:
// https://yousefamar.com/memo/articles/hacks/tailnet-name/


// being friendly; avoid rate limits
const sleepmillis = 2000

// cookie from logged in browser session
const cookie = "<your-cookie>";

// optional
const useragent = "";

(async () => {
  let found = false;
  while (!found) {
    const res = await fetch("https://login.tailscale.com/admin/api/tcd/offers", {
      "headers": {
        "Accept": "application/json, text/plain, */*",
        "Accept-Language": "en-US,en;q=0.9",
        "Accept-Encoding": "gzip, deflate, br, zstd",
        "Cache-Control": "no-cache",
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
      "body": null,
      "method": "GET"
    });

    const data = (await res.json()).data;

    console.log("--------------------------------------------------")
    for (const tcd of data.tcds)
      if (tcd.tcd.includes('<something>')
        || tcd.tcd.includes('<something>')
        || tcd.tcd.includes('<something>')) {
        console.log(">>>>> name match <<<<<")
        console.log(tcd);
        console.log(">>>>> ----- <<<<<")
        found = true;
      }
      else if (tcd.tcd.length <= 'xxxx-xxxx.ts.net'.length) {
        console.log(">>>>> length match <<<<<")
        console.log(tcd);
        console.log(">>>>> ----- <<<<<")
        found = true;
      }
      else {
        //console.log(tcd);
      }
    console.log("--------------------------------------------------")

    if (!found) {
      await new Promise(resolve => setTimeout(resolve, sleepmillis));
    }
  }
})();
