# Real-Time Game System Implementation on FPGA  
### Flappy Bird – Deterministic Hardware-Level Gameplay Architecture (VHDL)

## Project Background

This project was originally developed as part of a university group assignment.

This repository documents my individual technical contributions and system-level design in implementing a fully playable real-time game directly in hardware using VHDL on a Cyclone V FPGA board (DE0-CV).

The goal of this portfolio version is to present the architectural and systems engineering aspects of the project.

---

## Overview

A fully playable implementation of Flappy Bird rendered at 640x480 VGA resolution, with PS/2 mouse input handling and deterministic clock-driven gameplay logic.

Unlike engine-based development, all systems — state transitions, collision detection, procedural variation, rendering control, and timing — were implemented at the hardware level.

This project demonstrates:

- Deterministic real-time state control  
- Modular entity architecture  
- Procedural variation using LFSR  
- Collision and invincibility systems  
- Performance-aware hardware design  

---

## System Architecture

The system follows a control-path / data-path architecture.

A central Moore Finite State Machine (FSM) manages high-level state transitions:

- Main Menu  
- Playing  
- Death Menu  

Gameplay entities operate as modular components:

- Bird controller  
- Pipe recycling system  
- Gift system  
- LFSR random generator  
- Timer module  
- Character ROM for text rendering  
- VGA output controller  

The FSM acts as a display multiplexer and signal coordinator, ensuring state isolation and deterministic transitions.

(Insert architecture diagram here)

---

## Finite State Machine Design

A three-state Moore machine controls the game flow.

Transitions:

- Main Menu → Playing (mode selected)
- Playing → Death (collision or life = 0)
- Death → Retry / Main Menu

State logic is separated from entity logic, preventing unintended signal propagation.

This structure mirrors high-level game state management patterns used in modern engines.

(Insert FSM diagram here)

---

## Core Gameplay Systems

### Deterministic Update Logic

The FPGA operates at 50 MHz (divided via PLL).  
Gameplay timing is explicitly synchronized to clock edges.

There is no implicit “game loop” abstraction — motion, collisions, and scoring are defined through synchronous logic.

---

### Entity Recycling System (Object Pooling Concept)

Three pipe entities and three gift entities are recycled.

When reaching screen boundaries, they reposition to the right and continue movement.

This mimics object pooling techniques used in engine-based development to avoid runtime allocation.

---

### Procedural Variation (LFSR)

An LFSR generates pseudo-random heights for pipe gaps (range 30–329).

This provides gameplay variation without software-based RNG libraries.

Gift visibility is conditionally tied to pipe height, creating systemic interdependency.

---

### Collision & Invincibility System

Collision detection is area-overlap based.

On collision:
- A timer activates a 3-second invincibility window
- Bird flashes visually
- Life decrement is gated during invincibility

This demonstrates state-dependent behavioral modulation.

---

## Performance & Timing Constraints

Timing analysis (Quartus Prime) revealed:

- Maximum achievable frequency: 11.72 MHz  
- Target refresh: 25 MHz  

Analysis suggested that sequential logic in menu rendering may limit achievable FMAX.

This project required balancing gameplay complexity with hardware resource constraints.

Resource usage:

- 3194 ALMs (~17%)
- 817 registers
- <1% block memory
- 0 DSP blocks

---

## My Contributions

- Designed and implemented the Moore FSM control unit  
- Developed collision detection and invincibility timing logic  
- Implemented pipe recycling and enable chaining mechanism  
- Integrated LFSR-based procedural gap generation  
- Participated in performance bottleneck analysis  

---

## Lessons & Future Improvements

If expanding this project further:

- Refactor menu rendering logic to improve FMAX  
- Introduce sprite pipeline for richer visual design  
- Add pause state with gated clock domain  
- Further decouple rendering logic from gameplay state  

---

## Relevance to Game Systems Programming

This project strengthened my understanding of:

- Deterministic system design  
- State architecture  
- Modular entity interaction  
- Performance constraints under limited resources  
- Low-level rendering control  

Although implemented in hardware, the architectural patterns directly relate to engine-level gameplay systems.
