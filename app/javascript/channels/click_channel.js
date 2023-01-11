import consumer from "channels/consumer";

let shortened_url = window.location.pathname.split("/")[2];

consumer.subscriptions.create(
  { channel: "ClickChannel", shortened_url: shortened_url },
  {
    connected() {
      // Called when the subscription is ready for use on the server
      console.log("Connected to ClickChannel");
    },

    disconnected() {
      // Called when the subscription has been terminated by the server
    },

    received(data) {
      // If the clients URL pathname matches the data.shortened_url, update the click count
      let element = document.getElementById("url-click-count");
      element.innerHTML = data.click_count;
    },
  }
);