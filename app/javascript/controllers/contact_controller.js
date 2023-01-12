import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
  }

  validateInputs(e) {
    e.preventDefault();

    let inputs = document.querySelectorAll(
      "form[action='/contact'] input, form[action='/contact'] textarea"
    );

    let email_input = document.querySelector(
      "form[action='/contact'] input[type='email']"
    );

    let email_regex = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;

    inputs.forEach((input) => {
      if (input.value === "") {
        // Add an error below the input
        if (input.parentNode.querySelector(".text-danger")) {
          input.parentNode.querySelector(".text-danger").remove();
        }
        let error = document.createElement("div");
        error.classList.add("text-danger");
        error.innerHTML = "This field is required";
        input.parentNode.appendChild(error);

        input.classList.add("border-danger");
      } else {
        // Remove the error
        if (input.parentNode.querySelector(".text-danger")) {
          input.parentNode.querySelector(".text-danger").remove();
        }
        input.classList.remove("border-danger");
      }
    });

    if (email_regex.test(email_input.value) === false) {
      if (email_input.parentNode.querySelector(".text-danger")) {
      } else {
        let error = document.createElement("div");
        error.classList.add("text-danger");
        error.innerHTML = "Please enter a valid email address";
        email_input.parentNode.appendChild(error);
        email_input.classList.add("border-danger");
      }
    }

    // Get the number of inputs that have a class of text-danger
    let error_count = document.querySelectorAll(".text-danger").length;
    return error_count;
  }

  submitForm(e) {
    e.preventDefault();

    let contact_form = e.target.form;

    let num_errors = this.validateInputs(e);

    if (num_errors === 0) {
      contact_form.requestSubmit();

      e.target.classList.add("d-none");
      document
        .getElementById("submit-button-loading")
        .classList.remove("d-none");
    }
  }
}
