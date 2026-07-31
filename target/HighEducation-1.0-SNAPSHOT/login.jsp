<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>User Portal - Login</title>
<style>
  :root {
    --primary-color: #8b263e;       /* Deep Classic Crimson/Burgundy */
    --primary-hover: #6e1c2f;       /* Darker shade for buttons */
    --accent-bg: #fff5f5;           /* Very light soft red for section headers */
    --border-color: #d8b8b8;        /* Soft reddish-gray border */
    --text-main: #333333;
    --bg-main: #fcf8f8;              
  }

  * {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
  }

  body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background-color: var(--bg-main);
    color: var(--text-main);
    padding: 40px 10px;
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
  }

  .container {
    width: 100%;
    max-width: 440px;
    background: #ffffff;
    border-radius: 6px;
    box-shadow: 0 4px 15px rgba(139, 38, 62, 0.1);
    border: 1px solid var(--border-color);
    overflow: hidden;
  }

  /* Header Section */
  .form-header {
    background: linear-gradient(135deg, var(--primary-color), #a8324e);
    color: #ffffff;
    padding: 20px;
    text-align: center;
  }

  .form-header h2 {
    font-size: 20px;
    font-weight: 600;
    letter-spacing: 0.5px;
    text-transform: uppercase;
  }

  .form-header p {
    font-size: 12px;
    margin-top: 4px;
    opacity: 0.9;
  }

  .form-body {
    padding: 24px 28px;
  }

  /* Section Title Styling */
  .section-title {
    background-color: var(--accent-bg);
    color: var(--primary-color);
    padding: 6px 12px;
    font-size: 12px;
    font-weight: 700;
    border-left: 3px solid var(--primary-color);
    margin-bottom: 16px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .form-group {
    display: flex;
    flex-direction: column;
    margin-bottom: 14px;
  }

  label {
    font-size: 12px;
    font-weight: 600;
    color: #4a4a4a;
    margin-bottom: 5px;
  }

  label .required {
    color: var(--primary-color);
    font-weight: bold;
  }

  /* Compact Input & Select Controls */
  input[type=text],
  input[type=password],
  input[type=email] {
    width: 100%;
    padding: 6px 10px;
    font-size: 13px;
    height: 36px;
    color: var(--text-main);
    background-color: #fff;
    border: 1px solid var(--border-color);
    border-radius: 4px;
    transition: all 0.2s ease-in-out;
    outline: none;
  }

  input[type=text]:focus,
  input[type=password]:focus,
  input[type=email]:focus {
    border-color: var(--primary-color);
    box-shadow: 0 0 0 2px rgba(139, 38, 62, 0.15);
  }

  input::placeholder {
    color: #999;
    font-size: 12px;
  }

  /* Custom Checkbox Toggle */
  .show-password-group {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-top: -4px;
    margin-bottom: 16px;
  }

  .show-password-group input[type="checkbox"] {
    accent-color: var(--primary-color);
    cursor: pointer;
    width: 14px;
    height: 14px;
  }

  .show-password-group label {
    margin-bottom: 0;
    font-size: 12px;
    color: #666;
    cursor: pointer;
    font-weight: 500;
  }

  /* Submit Buttons Styling */
  .btn-submit {
    width: 100%;
    background-color: var(--primary-color);
    color: #ffffff;
    border: none;
    padding: 10px;
    font-size: 13px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    border-radius: 4px;
    cursor: pointer;
    transition: background-color 0.2s ease, transform 0.1s ease;
  }

  .btn-submit:hover {
    background-color: var(--primary-hover);
  }

  .btn-submit:active {
    transform: scale(0.99);
  }

  /* Error Alert Box */
  .error-message {
    background-color: #fce8e6;
    color: #c5221f;
    border: 1px solid #f5c6cb;
    padding: 8px 12px;
    border-radius: 4px;
    font-size: 12px;
    font-weight: 600;
    text-align: center;
    margin-top: 14px;
  }

  /* Divider */
  .divider {
    position: relative;
    text-align: center;
    margin: 22px 0;
  }

  .divider::before {
    content: "";
    position: absolute;
    top: 50%;
    left: 0;
    width: 100%;
    height: 1px;
    background-color: var(--border-color);
    z-index: 1;
  }

  .divider span {
    position: relative;
    z-index: 2;
    background-color: #ffffff;
    padding: 0 10px;
    font-size: 11px;
    font-weight: 700;
    color: #777;
    text-transform: uppercase;
  }

  /* Gmail / OTP Button Styling */
  .btn-gmail {
    width: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    background-color: #ffffff;
    color: #4a4a4a;
    border: 1px solid var(--border-color);
    padding: 9px;
    font-size: 13px;
    font-weight: 600;
    border-radius: 4px;
    cursor: pointer;
    transition: all 0.2s ease;
    margin-top: 10px;
  }

  .btn-gmail:hover {
    background-color: var(--accent-bg);
    border-color: var(--primary-color);
    color: var(--primary-color);
  }

  .btn-gmail img {
    width: 18px;
    height: 18px;
  }

  @media (max-width: 480px) {
    .container {
      margin: 10px;
      box-shadow: none;
    }
  }
</style>
</head>
<body>

  <div class="container">
    <!-- Header -->
    <div class="form-header">
      <h2>KARNATAKA SEVA SANGHA <br> </h2>
      <p>Higher Education Scholarship Portal</p>
    </div>

    <div class="form-body">
      <!-- Standard Login Form -->
      <form action="LoginServlet" method="post">
        <div class="section-title">Standard Authentication</div>

        <div class="form-group">
          <label for="username">Username <span class="required">*</span></label>
          <input type="text" id="username" name="username" placeholder="Enter your username" required autocomplete="username">
        </div>

        <div class="form-group">
          <label for="password">Password <span class="required">*</span></label>
          <input type="password" id="password" name="password" placeholder="Enter your password" required autocomplete="current-password">
        </div>

        <div class="show-password-group">
          <input type="checkbox" id="showPwd" onclick="togglePassword()">
          <label for="showPwd">Show Password</label>
        </div>

        <button type="submit" class="btn-submit">Log In</button>
      </form>

      <!-- Dynamic JSP Error Message Box -->
      <% if (request.getAttribute("error") != null && !request.getAttribute("error").toString().trim().isEmpty()) { %>
        <div class="error-message">
          <%= request.getAttribute("error") %>
        </div>
      <% } %>

      <!-- Divider -->
      <div class="divider">
        <span>OR</span>
      </div>

      <!-- OTP Form -->
      <form action="SendOTPServlet" method="post">
        <div class="section-title">Quick OTP Authentication</div>

        <div class="form-group">
          <label for="email">Registered Gmail <span class="required">*</span></label>
          <input type="email" id="email" name="email" placeholder="name@domain.com" required>
        </div>

        <button type="submit" class="btn-gmail">
          <img src="https://www.gstatic.com/images/branding/product/1x/gmail_2020q4_48dp.png" alt="Gmail logo">
          Send OTP to Gmail
        </button>
      </form>
    </div>
  </div>

  <script>
    function togglePassword() {
      const pwd = document.getElementById("password");
      pwd.type = pwd.type === "password" ? "text" : "password";
    }
  </script>

</body>
</html>