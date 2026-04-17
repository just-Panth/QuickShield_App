### 🛡️ QuickShield
**Parametric Income Infrastructure for the Quick-Commerce Economy**

---
### Pitch Deck 

https://drive.google.com/file/d/15vRan3lf1LDC8ssUQhh9V58ZP8DV60ts/view?usp=sharing

---

### 📖 Executive Summary

The quick-commerce revolution (10-minute deliveries) has fundamentally changed urban logistics. Platforms like **Blinkit, Zepto, and Swiggy Instamart** rely on a massive, hyper-local fleet of delivery partners. However, the financial model for these partners is fragile—they are paid per delivery, meaning their entire livelihood is completely exposed to external disruptions.

**QuickShield** is an open-source, AI-driven parametric insurance protocol designed specifically for this high-velocity gig economy. It replaces subjective loss-adjustment with worker-initiated, data-verified smart triggers. When the environment breaks down, **QuickShield** ensures the worker's income doesn't.

---

### ⚠️ The Problem: The Fragility of Hyper-Local Logistics

**The Persona: Rohan (Quick-Commerce Partner)**

Note

Rohan operates out of a "dark store" in a high-density urban zone. On a normal day, he completes 25–30 deliveries, earning approximately **₹900**. His economic survival—fuel, rent, and family remittances—is strictly tied to this daily baseline.

**The Disruption Reality**

In quick-commerce, "time" is the product. When external variables disrupt time, the worker's income collapses. These disruptions include:

* **Micro-Weather Events:** Localized flash floods or heavy rain that halt deliveries in a specific 3km radius.
* **Infrastructure Failure:** Severe traffic gridlock caused by accidents or unplanned civic events.
* **Environmental Hazards:** AQI (Air Quality Index) spiking above 400, leading to government-mandated slowdowns or health risks.
* **Civic Disruptions:** Unplanned curfews, local strikes, or sudden market/zone closures.

When an unexpected thunderstorm hits at 4:00 PM, order volumes might surge, but the ability to fulfill them drops to zero. Rohan might sit in the dark store for four hours, earning nothing. Traditional insurance covers his motorcycle if it crashes; it does nothing for his wallet when the city halts.

**The Reality:** *When these disruptions occur, gig workers bear 100% of the financial loss with zero safety net.*

---

### 💡 The Solution: Data-Driven Income Floors

**QuickShield** introduces a **Parametric Income Guarantee**. It shifts the "burden of proof" from the human to the data. When a worker requests a claim, **QuickShield** verifies the disruption by ingesting environmental and operational telemetry.

**The Core Economic Engine: Two-third (2/3) Guarantee**

*QuickShield guarantees **two-third (2/3)** of a worker's expected daily income during a verified disruption.*

**Why 2/3? (Mitigating Moral Hazard)** If the platform guaranteed 100% of income, it would incentivize workers to stay home at the slightest hint of rain. **By capping the floor at 2/3, QuickShield provides a vital safety net for survival without removing the financial incentive to work if conditions are safe.**

**The Payout Logic (Real-World Example):**

* **Expected Daily Baseline:** ₹900
* **QuickShield Guarantee (2/3):** ₹600
* **Disruption Event:** A 5-hour traffic gridlock halts operations.
* **Actual Earned by Rohan:** ₹200 (before the gridlock).
* **Automated Payout:** ₹600 - ₹200 = **₹400** deposited to UPI instantly.

---

### ⚙️ The 4-Layer Disruption Detection Engine

To trigger a payout, **QuickShield** requires a mathematical "handshake" between external environmental data and internal operational data to prevent false positives.

**Multi-Layer Verification System**
| Layer | Name | Source | Trigger Mechanism |
| :--- | :--- | :--- | :--- |
| **1** | **Environmental** | External APIs | [Temp 48°C](https://example.com), [Rain 65mm/2hr](https://example.com), AQI 350, or >60% zone velocity drop. |
| **2** | **Operational** | Delivery Data | Daily Deliveries drops < 40% of the worker's rolling 14-day average |
| **3** | **Risk Assessment** | ML Model | Hex-grid Risk Score (1-100) calibrates trigger sensitivity based on Historic Data & Topography. |
| **4** | **Peer Validation** | Network Data | >60% of riders in the specific dark store cluster show identical velocity drops. |

---

# 🛡️ Adversarial Defense & Anti-Spoofing Strategy (Market-Crash)

### The Threat Landscape: The Challenge of Simulated Presence

* **The Problem statement** ->The shift to a **worker-initiated claim model** introduces a specific vulnerability: **Simulated Presence**. Unlike automated systems, our model relies on a user declaring their inability to work due to local disruptions. This creates an incentive for fraudulent actors to use "Mock Location" tools and sophisticated GPS-spoofing software to simulate being stranded in a high-risk "Red Alert" zone while they are actually in a safe, unaffected area. Because standard X/Y GPS coordinates are easily manipulated by third-party applications, they are no longer sufficient for verifying a worker's physical reality.

* **Solution** -> To protect the collective insurance pool from depletion by fraudulent claims, without draining device batteries or utilizing restricted OS-level permissions, **QuickShield** has upgraded to a **Server-Side Physics & Network Validation Engine**. We differentiate genuine workers from spoofers by validating the *logical and physical consistency* of the data.

### Threat Matrix & Mitigation Architecture
| Defense Layer | Threat Vector | Detection Mechanism | Automated System Action |
| :--- | :--- | :--- | :--- |
| **1. Device Physics Validation** | Mock-Location Apps (GPS Spoofing) | **Z-Axis & Altitude Invariance:** Real GPS altitude naturally fluctuates. The system detects unnatural 0.0 or perfectly static altitude data across multiple polling pings. | **Hard Reject:** Claim voided due to mathematical certainty of spoofed telemetry. |
| **2. State Synergy (B2B)** | False "Stranded" Claims | **Cross-Platform State Check:** Cross-references the claim timestamp with the delivery platform's webhook (e.g., claiming "trapped in flood" while simultaneously marking an order "Delivered"). | **Hard Reject:** Claim voided; worker profile flagged for review. |
| **3. Network Metadata Analysis** | Centralized Syndicate Farms | **IP & Subnet Overlap:** Analyzes routing data to detect if 50+ "stranded" claims are originating from the exact same residential broadband IP or known commercial VPN nodes. | **Circuit Breaker:** Instantly freezes automated payouts for the overlapping cluster. |
| **4. Spatial-Temporal Logic** | Teleportation / Account Sharing | **Time-to-Distance Impossibility:** Calculates the Δ (change) between the last valid platform login and the claim location. Flags velocities exceeding physical speed limits. | **Hard Reject:** Claim voided for violating physical constraints. |
| **5. Behavioral Improbability** | Automated Scripted Attacks | **Submission Synchronicity:** Human behavior is random. The system detects if dozens of claims hit the webhook within the exact same millisecond window. | **Circuit Breaker:** Freezes cluster payouts to block automated liquidity drains. |
| **6. Graceful Degradation (UX)** | False Positives (Honest workers in bad networks) | **Soft Flags for Ambiguous Data:** Distinguishes between malicious spoofing (static altitude) and genuine storm disruption (loss of GPS signal entirely). | **Delayed Verification Queue:** Asks worker for a simple asynchronous live photo when connection returns. |

**The UX Balance: Protecting the Honest Worker**

A heavy-handed fraud system risks penalizing the exact people it is meant to protect. Severe storms naturally degrade network connectivity. **QuickShield** handles ambiguous data through **Asynchronous Micro-Verification**.

If a worker's GPS simply drops out, they are not banned. Instead, the claim enters a delayed queue. Once the worker's internet stabilizes, the app prompts a lightweight task: *"Your location data was interrupted by the storm. Please upload a quick photo of your parked bike or the flooded street to release your funds."*

This ensures honest workers receive their payout with minimal friction, while making it operationally impossible for a syndicate farm sitting in a single basement to fake hundreds of unique, real-time photos.

---

### 📉 Operational Disruption Logic: New User Protocol

Since new delivery partners do not have a 14-day historical income baseline, **QuickShield** utilizes **Zone-Level Aggregates** to provide immediate protection. This ensures that a worker is covered even if a disruption occurs on their very first day.

**Threshold Parameters for New Users**

* **Zone Standard Baseline:** The average hourly delivery volume of the top 20% of active riders in the specific dark store/zone over the last 7 days.
* **Activity Drop Trigger:** A disruption is verified for the new user if the *entire zone's* delivery success rate falls **< 40%** of the Zone Standard.
* **New User Safety Net:** During the first 14 days, the "Expected Income" used for payouts is set to the **Zone Median Income** (e.g., ₹700/day) until a personalized baseline is established.

**The "Cold Start" Logic Process**

1.  **Initial Onboarding:** New user joins; personalized data is at zero.
2.  **Zone Mapping:** The AI links the user to their primary assigned Dark Store zone.
3.  **External Event:** A disruption (e.g., severe AQI or Strike) is detected via APIs.
4.  **Peer-Verification:** The system checks if the *established* riders in that zone have stopped moving.
5.  **Instant Coverage:** If the zone is "down," the new user receives a payout based on the **Zone Median**, ensuring they don't face a total loss during their first week.

**Transition:** After 14 days of active service, the system automatically migrates the worker from the "Zone Standard" to their "Personalized Baseline" for more accurate, tailormade protection.

---

### 💳 The Financial & Premium Model

**QuickShield** operates on a high-frequency, low-friction **Weekly Micro-Premium** structure. It is treated like a seamless subscription, billed via **auto-pay** or deducted directly from platform earnings to align with the gig worker's natural payout cycle.

---

### 🚫 Standard Policy Exclusions (Risk Boundary)

To ensure the long-term solvency of the **QuickShield** liquidity pool and maintain affordable premiums for all partners, certain high-magnitude events are excluded from standard parametric coverage. These represent "Systemic Risks" that fall outside the scope of localized operational disruptions.

#### 1. Detailed Systemic Exclusions

**⚔️ Acts of War, Terrorism, and Civil Commotion**

* **Definition:** Coverage is strictly excluded for any loss resulting from declared or undeclared war, insurrection, rebellion, revolution, or any act of terrorism as defined by international law.
* **The "Correlated Risk" Logic:** Unlike a local thunderstorm affecting a 5km radius, war causes a total systemic collapse of urban logistics. This would trigger 100% of the user base simultaneously, leading to an instant "Correlated Risk Collapse" of the liquidity pool.
* **Infrastructure Dependency:** **QuickShield** relies on external APIs (Layer 1) and delivery webhooks (Layer 2). In a state of war, these data sources are likely to be offline or compromised, making data-driven verification technically impossible.

**🦠 Global Pandemics and Health Emergencies**

* **Definition:** Exclusions apply to disruptions caused by any pathogen, virus, or bacterium resulting in a "Public Health Emergency of International Concern" or government-mandated "Stay-at-Home" orders.
* **The "Double-Sided" Disruption:** During a pandemic, the disruption hits the dark stores, the customers, and the workers simultaneously. This is an uninsurable event for a private micro-insurance protocol.
* **Trigger Ambiguity:** While parametric triggers work for "Micro-Weather" events with clear start/stop times, pandemics have "long-tail" recovery periods that cannot be modeled in a weekly micro-premium structure.

**☢️ Nuclear, Chemical, and Biological Contamination**

* **Definition:** No coverage is provided for disruptions caused by the release of radioactive, poisonous, or hazardous chemical agents.
* **Unmodelable Risk:** These events are considered "Uninsurable" because there is no historical operational data (e.g., from our 2024 baseline) to accurately predict the frequency or severity of such a disruption.

#### 2. Operational & Behavioral Exclusions

* **Planned Maintenance:** Claims are void if the disruption is due to scheduled platform downtime or pre-announced dark store closures.
* **The 48-Hour "Cooling Off" Period:** Claims cannot be filed within the first 48 hours of a new weekly subscription to prevent "Adverse Selection" (buying insurance only when a storm is visible).
* **Fraudulent "Simulated Presence":** Any claim flagged for altitude invariance or GPS spoofing results in an immediate 30-day policy suspension and claim voiding.

####🏛️ 3. The IRDAI "CAT" Protocol (Catastrophe Event)

> **Regulatory Override:** In the event of a Tier 1 Natural Catastrophe, the **Insurance Regulatory and Development Authority of India (IRDAI)** protocols may supersede standard policy exclusions.

When a major event occurs (e.g., the Chennai floods or a major cyclone in Odisha), the IRDAI typically issues emergency circulars that mandate the following:

* **Rule Relaxation:** Insurance providers are ordered to relax standard "Strict Proof" requirements.
* **Waiver of Documentation:** Force insurers to waive standard documentation that might be impossible to produce during a disaster.
* **Mandated Velocity:** Platforms are required to process and mandate faster payouts to ensure immediate liquidity for victims.
* **Fast-Track Desks:** Requirement to set up special fast-track claim settlement desks to bypass the standard verification queue.

*This protocol ensures that while QuickShield protects against localized "Micro-Weather," the state infrastructure provides a backstop for massive, systemic regional disasters.*

### A. The Asynchronous Photo Vulnerability (EXIF Spoofing & Deepfakes)

* **The Flaw:** Allowing offline photo uploads later invites gallery deepfakes and manipulated EXIF metadata.
* **The Fix (Hardware-Locked Capture):** QuickShield strictly blocks gallery access. Offline workers must use the in-app camera, which bypasses editable EXIF data. It pulls raw GPS/timestamp data directly from the OS and securely hashes it with the image locally before queuing for upload.
* **Why it’s Feasible:** Leverages lightweight native Flutter plugins (camera, geolocator). Generating a local hash requires almost zero computational power, perfectly fitting the 2GB/3GB RAM constraint of budget Android devices.

### B. The Platform Penalty Conflict (Algorithmic Retaliation)

* **The Flaw:** If QuickShield pays a worker to stay home during a localized disruption, the delivery app's algorithm might penalize or suspend them for ignoring orders.
* **The Fix (Bifurcated GTM Logic):**
    * **D2C Model:** Relies on existing market reality. Platforms already pause zones ("weather-switches") during severe storms, protecting the worker's job while QuickShield protects their wallet.
    * **B2B Model:** Introduces an *"Algorithmic Amnesty"* webhook. For "grey-area" disruptions (like localized traffic gridlock), QuickShield pings the partner platform to temporarily freeze penalty metrics for riders in that specific hex-grid.
* **Why it’s Feasible:** Requires zero new engineering for the D2C side, and standard REST API webhooks for the B2B side.

---

### 🤖 Dynamic Pricing Algorithm

To ensure fair and precise pricing, premiums are recalculated every Sunday night for the upcoming week based on a composite risk formula:

* 🏠 **Base Rate:** ₹80 — ₹150 per week.
* 📍 **Zone Risk Modifier:** Applied if the upcoming week features monsoon warnings or if the worker is assigned to a notoriously congested dark store.
* 📈 **Earning Tier:** Workers opting for higher baseline coverage (e.g., ₹1,200/day vs. ₹600/day) pay proportionally more.
* 📜 **Contract Nature:** A 1-month rolling agreement (Exatly 35 days i.e 5 weeks) to ensure the risk pool maintains enough capital buffer to survive consecutive weeks of severe weather.

---

### 📊 Deliverable Tracking

* **Weekly Pricing Model:** Structured to match typical gig earnings.
* **Dynamic Premium Logic:** Integrated with hyper-local risk factors changes dynamically based on the score.
* **Financial Sustainability:** Rolling contract ensures long-term pool stability.

---

### 🏗️ Architecture

**QuickShield** is built to operate in low-bandwidth, low-memory environments, specifically targeting budget Android devices (2GB/3GB RAM) commonly used by delivery partners.

Architecture Flow - 
<img width="940" height="627" alt="image" src="https://github.com/user-attachments/assets/e87dd05e-539c-415b-b86f-cb534a98cfab" />

---

## 🧪 Simulation Engine: The "Zero-Touch" Proof of Concept
To demonstrate the real-time responsiveness of QuickShield, we have developed a Visual Disruption Simulator. This environment allows judges to witness the transition from a "Normal Earning State" to an "Automated Payout State" triggered by AI agents.

<img width="940" height="838" alt="image" src="https://github.com/user-attachments/assets/e569b674-016a-42f7-a373-df3347e63200" />

---

### 👾 Dynamic Disruption Triggering

The simulator bypasses traditional, slow claim filing by using a **Simulated External API** (Mocking OpenWeather/Google Maps Traffic).

* **Scenario A (Baseline):** Sunny weather, normal traffic. The worker's "Actual Earnings" align with the "Expected Income." No trigger.
* **Scenario B (Disruption):** A simulated "Heavy Rain" event is triggered.
    * The **Environmental Layer** detects the storm.
    * The **Operational Layer** confirms a >40% drop in zone delivery volume.
    * **Result:** The system verifies the worker's request and initiates 2/3 of the income and initiates a mock UPI payout.

### ⚡ Technical Highlights of the Simulation

* **Real-Time Telemetry:** Watch the "Disruption Score" climb in real-time as environmental variables worsen.
* **Instant Ledger Updates:** The worker's digital wallet reflects the payout within seconds of the disruption verification—proving the "Zero-Touch" promise.
* **ML Integration:** The simulation demonstrates how the **XGBoost model** adjusts the "Zone Risk Score" dynamically as the storm intensity fluctuates.

**Important**

*Our simulation is purely on synthetic data and assumptions based on data collected for the cumulative year 2024*

---

### 🛠️ Tech Stack

**QuickShield's** architecture is engineered for high performance on low-end hardware and reliable data ingestion in volatile environments.

* **🪟 Client App (Frontend): Flutter (Dart)**
    * Compiles directly to optimized native ARM code, ensuring a fluid UI even on budget devices with 2GB RAM.
    * Utilizes robust local caching (via **Hive** or **SQLite**) to function effectively on spotty 2G/3G networks while maintaining background telemetry for the disruption engine.
* **⚙️ Backend: Node.js (Express)**
    * Designed for asynchronous, high-volume concurrent webhook ingestion from external delivery platforms.
* **🗄️ Database: PostgreSQL + Redis**
    * **PostgreSQL:** Handles relational data including user profiles, financial ledgers, and contract histories.
    * **Redis:** Powers high-speed caching of live zone maps, active worker sessions, and peer-to-peer consensus checks.

* **🧠 Intelligence Engine: Python**
    * Leverages **scikit-learn** for Layer 6 behavioral anomaly detection.
    * Uses **XGBoost** for predicting zone-level disruption probabilities and calculating dynamic premium pricing.

---

### 📈 Go-To-Market (GTM) Strategy

**QuickShield** employs a dual-track growth strategy to ensure both rapid scalability through platform partnerships and accessibility for independent gig workers.

#### 🪟 D2C Model: Independent Worker Empowerment

*Target: Multi-platform freelancers and independent gig workers*

For workers who switch between multiple apps, **QuickShield** offers an independent, platform-agnostic safety net.

* **Independent Mobile App:** A dedicated Flutter-based app for workers to manage their own coverage.
* **UPI AutoPay Integration:** Leverages India’s UPI stack for automated, recurring weekly micro-payments.
* **Multi-Platform Support:** Since the model is parametric and zone-based, it protects the worker regardless of which delivery app they are currently logged into.
* **Worker-Centric Dashboard:** Real-time visibility into active coverage zones and historical payout transparency.

#### 🏢 B2B Model: Platform Integration

*Target: Zomato, Swiggy, Zepto, Blinkit*

This model focuses on deep integration within the existing delivery infrastructure to provide seamless, large-scale coverage.

* **API-First Integration:** **QuickShield** embeds directly into the delivery partner's native app.
* **Automatic Premium Deduction:** Premiums are deducted weekly from the worker’s payout ledger, ensuring zero payment friction.
* **Direct Payout Pipeline:** When a worker submits a claim during a verified disruption, compensation is pushed directly into the worker’s platform wallet.
* **Operational Synergy:** Delivery platforms benefit from higher rider retention and morale during adverse conditions.

---

### 🚀 Key Features

* Automated insurance payouts
* On-demand claim requests
* Real-time disruption detection
* Weekly micro-premium model
* Fraud detection system
* Scalable architecture

---

### 🎯 Vision

**Important**

**QuickShield** ensures that no gig worker loses income due to factors beyond their control by providing a reliable, automated financial safety net.

---

### 👥 Team

**Chai_Pe_Charcha**

---

### 📌 Status

🚧 Currently under development as part of Guidewire DevTrails Hackathon 2026

