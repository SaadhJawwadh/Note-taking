# Everything App Design System

## Overview
This document outlines the core design language, tokens, and component guidelines for the Everything App. The design focuses on a premium, tactile, dark-mode-first aesthetic with modern glassmorphism elements, micro-interactions, and Material 3 principles.

## 1. Colors
The app utilizes a dark, high-contrast palette with vibrant accents to create a premium feel.

### Base Colors
- **True Black Background**: `#000000`
- **Dark Surface (Base)**: `#1E1E1E`
- **Surface Container High**: `#252529` (Used for Cards)
- **Surface Container Highest**: `#2C2C30` (Used for Inputs and overlays)

### Accent Colors
- **Modern Purple (Primary)**: `#6B4EFF`
- **Soft Pink (Secondary/Accent)**: `#FF85C2`
- **Error Red**: `#FF453A`

### Text Colors
- **Text Primary**: `#F2F2F7` (High emphasis)
- **Text Secondary**: `#8E8E93` (Medium emphasis, subtitles)

## 2. Typography
- **Primary Font Family**: `Rubik`
- **Headings**: High contrast, bold (`FontWeight.bold`), crisp edges.
- **Body Text**: Medium weight (`FontWeight.w500`), subtle and highly readable.
- **Labels**: Small, precise, semi-bold.

## 3. Shapes & Radii
The interface avoids sharp edges in favor of soft, approachable curves.
- **Cards & Modals**: `16px` border radius (`BorderRadius.circular(16)`).
- **Floating Action Buttons (FAB)**: Pill-shaped (`StadiumBorder()`).
- **Input Fields**: `12px` border radius (`BorderRadius.circular(12)`).
- **Chips / Filters**: Pill-shaped with `20px` border radius (`BorderRadius.circular(20)`).

## 4. Component Specs
### Cards
- **Background**: Filled with `Surface Container High` (`#252529`).
- **Elevation**: `0px` (Flat, relying on color contrast for depth rather than shadows).
- **Interactions**: Tap feedback (ripples) and long-press contextual menus.

### Input Fields
- **Background**: Filled with `Surface Container Highest` (`#2C2C30`).
- **Borders**: Borderless (`BorderSide.none`).

### Buttons & FABs
- **FAB Appearance**: Uses `primaryContainer` and `onPrimaryContainer` for contrast.
- **Elevation**: `4px` for slight lift.

### Tag/Filter Chips
- **Selected State**: Solid Primary background, no borders, bold text.
- **Unselected State**: Transparent background, Outline border (`#8E8E93` or tinted), medium text weight.

## 5. Interactions & Aesthetics
- **Tactile Feedback**: Immediate ripple effects, scaling, and elevation changes on touch.
- **Micro-Animations**: Snappy transitions (~300ms) using the `animations` package (e.g., `FadeThroughPageTransitionsBuilder` and `OpenContainer`).
- **Dynamic Theming**: Dynamic color mappings derived from `ColorScheme.fromSeed(...)` based on note tag colors, ensuring perfect contrast across light and dark modes.
