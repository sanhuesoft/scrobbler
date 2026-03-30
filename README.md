# Apple Music Scrobbler for macOS

A lightweight, modern menu bar application that automatically scrobbles your Apple Music playback to Last.fm. Built with **Swift 6** and optimized for **macOS 26**.

## Features

* **Automatic Scrobbling**: Automatically detects Apple Music playback and scrobbles tracks after a 30-second listening threshold.
* **Menu Bar Interface**: A clean, native UI following macOS 26 design guidelines.
* **Real-time Status**: Dynamic icons and color-coded states (Waiting, Success, Error) to keep you informed.
* **Secure Auth**: Implements Last.fm's 2.0 API authentication flow.

## Requirements

* **macOS 26.0** or later.
* A Last.fm account and API credentials.

## Setup

The app requires your Last.fm API credentials to be set as environment variables for security:

1.  Obtain your API Key and Secret from [Last.fm API](https://www.last.fm/api/account/create).
2.  Set the following variables in your environment:
    * `LASTFM_API_KEY`
    * `LASTFM_API_SECRET`

## Usage

1.  **Launch**: Open the application.
2.  **Authorize**: Click "1. Autorizar en Last.fm" to open your browser and grant permission.
3.  **Confirm**: Return to the app and click "2. Completar inicio de sesión."
4.  **Listen**: Play music on Apple Music; the app will handle the rest.

## Tech Stack

* **Language**: Swift 6 (Concurrency-first)
* **Framework**: SwiftUI
* **Observation**: `@Observable` macro for state management
* **Communication**: `DistributedNotificationCenter` for system-wide Apple Music events

---
*Note: This repository provides the application in a pre-compiled format.*
