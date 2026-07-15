# TechSmart Shop Flutter Frontend

Flutter customer application for the **TechSmart Shop e-commerce platform**, powered by a Spring Boot backend.

<p>
  <img src="https://img.shields.io/badge/Flutter-Mobile-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-Language-0175C2?style=flat-square&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Backend-Spring%20Boot-6DB33F?style=flat-square&logo=springboot&logoColor=white" alt="Spring Boot">
  <img src="https://img.shields.io/badge/Platform-Android%20%26%20iOS-lightgrey?style=flat-square" alt="Android and iOS">
</p>

## Overview

TechSmart Shop is a Flutter-based customer storefront for browsing products, managing a cart, placing orders, making simulated payments, tracking deliveries, receiving notifications, and managing post-order actions such as cancellation and return requests.

The application communicates with a secured Spring Boot REST API backend.

## Related Repository

- Spring Boot Backend: https://github.com/mdwoalinur/techsmart-shop-flutter-backend

## Main Features

- Customer authentication
- Product browsing and searching
- Product details
- Shopping cart
- Checkout workflow
- Multiple payment options
- Mobile wallet payment simulation
- Cash on Delivery
- Order history
- Order details
- Order timeline
- Order cancellation
- Return request flow
- Delivery tracking
- Customer notifications
- Notification preferences
- Profile management
- Backend-driven order and payment status
- Customer data isolation
- Physical-device-tested Android workflow

## Technology Stack

- Flutter
- Dart
- Provider
- HTTP
- REST API
- Spring Boot Backend
- JWT Authentication
- Android
- iOS

## Payment Options

The application supports multiple payment workflows.

### Mobile Wallet

Backend-driven payment simulation for:

- bKash
- Nagad
- Rocket
- Upay
- SureCash
- Tap

### Other Payment Methods

- Online Payment
- Bank Transfer
- Mobile Transfer
- Cash on Delivery

Cash on Delivery does not mark an order as paid during checkout. Payment collection and reconciliation are handled by the backend workflow.

## Mobile Wallet Simulation

The mobile wallet flow is intended for development, testing, and demonstration purposes only.

It does not:

- Connect to real wallet provider APIs
- Collect real wallet credentials
- Allow the client to determine payment amount
- Allow the client to determine payment success
- Automatically post accounting entries without backend confirmation

The Spring Boot backend controls:

- Payment amount
- Provider selection validation
- Payment result
- Reference handling
- Wallet number masking
- Payment status
- Accounting posting

### Local Test Credentials

```text
Verification code: 123456
Payment PIN: 12345
