// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

// if the duration is zero, return "done"
// if the duration is less than a minute, return "{seconds}s"
// if the duration is less than an hour, return "{minutes}m {seconds}s"
// if the duration is less than a day, return "{hours}h {minutes}m {seconds}s"
// if the duration is less than a year, return "{days}d {hours}h {minutes}m {seconds}s"
function formatDuration(seconds) {
  if (seconds === 0) {
    return "done";
  }

  let minutes = Math.floor(seconds / 60);
  let hours = Math.floor(minutes / 60);
  let days = Math.floor(hours / 24);
  let years = Math.floor(days / 365);

  if (years > 0) {
    return `${years}y ${days % 365}d ${hours % 24}h ${minutes % 60}m ${
      seconds % 60
    }s`;
  } else if (days > 0) {
    return `${days}d ${hours % 24}h ${minutes % 60}m ${seconds % 60}s`;
  } else if (hours > 0) {
    return `${hours}h ${minutes % 60}m ${seconds % 60}s`;
  } else if (minutes > 0) {
    return `${minutes}m ${seconds % 60}s`;
  } else {
    return `${seconds}s`;
  }
}

let Hooks = {};

Hooks.Countdown = {
  tick() {
    let seconds = Math.floor((this.target - new Date()) / 1000);
    if (seconds <= 0) {
      this.el.innerHTML = "done";
      setTimeout(() => {
        this.pushEvent("countdown-ended", {});
        console.debug("sent countdown-ended event");
      }, 500);
      return;
    } else {
      this.el.innerHTML = formatDuration(seconds);
      this.timeout = setTimeout(() => this.tick(), 1000);
    }
  },
  mounted() {
    this.target = new Date(this.el.dataset.target);
    this.tick();
  },
  updated() {
    clearTimeout(this.timeout);
    this.mounted();
  },
  destroyed() {
    clearTimeout(this.timeout);
  },
};

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
