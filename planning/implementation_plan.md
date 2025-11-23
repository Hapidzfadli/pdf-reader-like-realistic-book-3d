# PDF Reader App - Technical Blueprint

## Overview
This document serves as the comprehensive blueprint for the "Lumina" PDF Reader application. It details the architecture, component design, and feature specifications for the web-based prototype.

## User Review Required
> [!NOTE]
> This blueprint replaces visual mockups for the **Reflow Mode**, **Settings**, and **File Picker** screens. The descriptions below will serve as the source of truth for implementation.

## Core Architecture
- **Framework**: React (Vite)
- **Styling**: Tailwind CSS (Dark Mode default)
- **State Management**: React Context API (for global settings like Theme, Font Size)
- **Routing**: React Router (or conditional rendering for prototype simplicity)
- **Animations**: Framer Motion

## Component Specifications

### 1. Splash Screen (`SplashScreen.jsx`)
- **Visuals**: Central "Lumina" logo, subtle gradient background (`bg-slate-900` to `bg-slate-800`).
- **Behavior**: Fades in logo, holds for 2s, fades out to Home.

### 2. Home / Library (`HomeScreen.jsx`)
- **Layout**:
    - **Header**: "Good Evening, [User]" with Avatar.
    - **Recent Carousel**: Horizontal scroll of book covers with progress bars.
    - **Library Grid**: 2-column grid of book thumbnails.
    - **Bottom Nav**: Fixed bar with icons (Home, Search, Favorites, Settings).
- **Interactions**: Tapping a book navigates to `ReaderScreen`.

### 3. Reader View (`ReaderScreen.jsx`)
- **Core Engine**: `react-pageflip` for 3D page turning.
- **Overlay UI**:
    - **Top Bar**: Back button, Book Title, Bookmark toggle.
    - **Bottom Bar**: Page scrubber slider, "View Options" button.
- **Gestures**: Swipe to flip, tap center to toggle controls.

### 4. Annotation Tools (`AnnotationToolbar.jsx`)
- **Trigger**: Appears on text selection.
- **UI**: Floating pill-shaped menu (black/glassmorphism).
- **Actions**:
    - 🟡 Highlight (Yellow)
    - 🔴 Underline (Red)
    - 📝 Note (Opens modal input)
    - 📋 Copy

### 5. Navigation Drawer (`NavigationDrawer.jsx`)
- **Layout**: Slide-in panel from the left.
- **Tabs**:
    - **Chapters**: List of TOC items.
    - **Bookmarks**: List of saved pages.
    - **Annotations**: List of user highlights/notes.
- **Search**: Input field at top to filter results.

### 6. Reflow Mode (`ReflowReader.jsx`)
> *Missing Visual Mockup - Specification:*
- **Concept**: "Liquid Mode" - extracts text from PDF and reflows it as standard HTML text.
- **UI**:
    - **Toggle**: Switch in top bar to enable/disable.
    - **Content**: Single column text, optimized for mobile width.
    - **Typography**: User-adjustable font size and line height.
    - **Images**: Rendered inline, full width.

### 7. Settings Screen (`SettingsScreen.jsx`)
> *Missing Visual Mockup - Specification:*
- **Layout**: Standard list view with section headers.
- **Sections**:
    - **Appearance**:
        - Theme (Dark/Light/Sepia)
        - Brightness Slider
    - **Reading**:
        - Font Face (Serif/Sans)
        - Page Transition (Flip/Scroll)
    - **Account**:
        - Profile details (read-only)
        - Storage usage

### 8. File Picker (`FileImport.jsx`)
> *Missing Visual Mockup - Specification:*
- **Layout**: Modal or full screen.
- **Sources**:
    - **Device Storage**: Triggers system file picker.
    - **Cloud Services**: Mock buttons for Drive/Dropbox.
- **Recent Files**: List of recently opened PDFs.

## Data Model (`mockData.js`)
- **Books**: Array of objects `{ id, title, author, coverUrl, content, progress }`.
- **Annotations**: Array of objects `{ bookId, page, type, content, color }`.

## Implementation Steps
1.  **Setup**: Initialize Vite + Tailwind.
2.  **Shell**: Build App container and routing.
3.  **Screens**: Implement Splash, Home, Reader (Flip).
4.  **Features**: Add Annotations, Navigation Drawer.
5.  **Missing UI**: Implement Reflow, Settings, File Picker based on specs above.
