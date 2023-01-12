import consumer from "channels/consumer";

let shortened_url = window.location.pathname.split("/")[2];

let is_url_path = window.location.pathname.includes("/urls/");

// Only subscribe to the channel if we are on the shortened URL page
if (is_url_path) {
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
        let element = document.getElementById("url-click-count");
        element.innerHTML = data.click_count;
      },
    }
  );
}
