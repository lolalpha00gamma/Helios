# Helios Vorschläge — 2026-09-09 (Pass 45, 1.6.96)

Stand 1.6.96. Closedness EMA. ROI Hysterese + Full/4. Coast-Cap palm. PinchGate ratio.

## Gelandet in 1.6.96

- pinchClosednessSmooth vor pinchAnalog. GestureEngine analogClosed.
- visionRoiHolds Miss 1. lastRoi bleibt.
- visionRoiPeriodicFull jedes 4. Tick.
- hudCoastCapScaled palmWidth. Overlay live.
- PinchGate closedness nur ratio, nicht dProx-min.

## Erweiterung (neu)

815. **CameraBroker XPC + IOSurface** mit Aegis. P0.
816. **HeliosAegisKit.**
817. **VNTrackObjectRequest.** ROI sitzt — Track lohnt.
818. **Per-Finger-Kontakt.**
819. **palmHighpass auf UV-Position.**
820. **Ampel-Ring Overlay.**
821. **Rechtsklick-HUD.**
822. **Click-Ring Overlay.**
823. **CGEventSource-State.**
824. **Desk-View Crop.**
825. **IOHIDEventSystemClient.**
826. **Watch Double-Tap.**
827. **MediaPipe Hands.**
828. **Overlay CAMetalLayer.**
829. **LiDAR.**
830. **Continuity 15-fps Probe** (inputPriority sitzt, Leiter 540 hält).
831. **Mission-Control Spread.**
832. **Two-pointer origin lock.**
833. **Pinch-Hysterese palmWidth.**
834. **Gesture-Macro.**
835. **SpaceMap nur als Start.**
836. **CGEvent tapHold.**
837. **pinch3DVeto Depth-Reach.**
838. **emptyHandsRecover(elapsed:)** Fold.
839. **SpaceMap Recenter nach Wake.**
840. **formatPromoted nach inputPriority.** 720p24 → 1080p15.
841. **ROI scale 1,6** Continuity.
842. **Cover-Lead Homographie Blend.**
843. **Bezel-Hop Blend** 200 ms.
844. **Two-hand HUD-Lerp unabhängig.**
845. **pinchFingerContact analog mix.**
846. **DisplayLink Pause bei Freeze.**
847. **Vision joint-conf analog mix.**
848. **pinchSpan palmWidth-EMA am Hold.**
849. **useCover Homographie** Cover-Lead (tot).
850. **Core Haptics** Pinch-Close.
851. **Gaze-Click** ARKit + Pinch AND.
852. **Stage-Manager Space-Lock.**
853. **Accessibility Switch-Control Bridge.**
854. **Siri-Shortcut Pinch-Macro.**
855. **cameraMutexStampFresh Write.** Tests grün, CameraSession tot — Aegis liest den Stamp.
856. **pinchClosedness freeze** solange analog held.
857. **Continuity 420v luma lift** für Pinch-Kontrast.
858. **format ladder skip 1080** wenn fps < 12.
859. **clutchJiggleScaled nach analog-Hysterese.**
860. **lastRoi clamp palm×1,6** bei Miss 1.

P0: CameraBroker. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.

# Helios Vorschläge — 2026-09-09 (Pass 44, 1.6.95)

Stand 1.6.95. analog Hysterese, uniqueID persist, Leiter 540/360.

## Gelandet in 1.6.95

- pinchAnalogClosed held 0,48 / start 0,58. GestureEngine pinchHeld.
- trackIDPersist Chirality. HandTracker Slot in-place, kein T3.
- cameraFormatHeightPrefers720 hält 540/360.

## Erweiterung (neu)

777. **CameraBroker XPC + IOSurface** mit Aegis. P0.
778. **HeliosAegisKit.**
779. **VNTrackObjectRequest.** ROI sitzt — Track lohnt.
780. **Per-Finger-Kontakt.**
781. **palmHighpass auf UV-Position.**
782. **Ampel-Ring Overlay.**
783. **Rechtsklick-HUD.**
784. **Click-Ring Overlay.**
785. **CGEventSource-State.**
786. **Desk-View Crop.**
787. **IOHIDEventSystemClient.**
788. **Watch Double-Tap.**
789. **MediaPipe Hands.**
790. **Overlay CAMetalLayer.**
791. **LiDAR.**
792. **Continuity 15-fps Probe** (inputPriority sitzt, Leiter 540 hält).
793. **Mission-Control Spread.**
794. **Two-pointer origin lock.**
795. **Pinch-Hysterese palmWidth.**
796. **Gesture-Macro.**
797. **SpaceMap nur als Start.**
798. **CGEvent tapHold.**
799. **pinch3DVeto Depth-Reach.**
800. **emptyHandsRecover(elapsed:)** Fold.
801. **SpaceMap Recenter nach Wake.**
802. **ROI-Hysterese 2 Frames.**
803. **formatPromoted nach inputPriority.** 720p24 → 1080p15.
804. **pinchClosedness EMA.**
805. **ROI scale 1,6** Continuity.
806. **ROI full jedes 4. Tick.**
807. **Cover-Lead Homographie Blend.**
808. **Bezel-Hop Blend** 200 ms.
809. **hudCoast Cap aus palmWidth.**
810. **Two-hand HUD-Lerp unabhängig.**
811. **pinchFingerContact analog mix.**
812. **DisplayLink Pause bei Freeze.**
813. **Vision joint-conf analog mix.**
814. **pinchSpan palmWidth-EMA am Hold.**

P0: CameraBroker. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.

# Helios Vorschläge — 2026-09-09 (Pass 43, 1.6.94)

Stand 1.6.94. HUD-Lerp zwischen Samples.

## Gelandet in 1.6.94

- hudLerpT (now−prevAt)/span. t=1 am Sample. Coast bleibt.

## Erweiterung (neu)

741. **CameraBroker XPC + IOSurface** mit Aegis. P0.
742. **HeliosAegisKit.**
743. **VNTrackObjectRequest.** ROI sitzt — Track lohnt.
744. **Per-Finger-Kontakt.**
745. **palmHighpass auf UV-Position.**
746. **Ampel-Ring Overlay.**
747. **Rechtsklick-HUD.**
748. **Click-Ring Overlay.**
749. **uniqueID persist nach Remint.**
750. **CGEventSource-State.**
751. **Desk-View Crop.**
752. **IOHIDEventSystemClient.**
753. **Watch Double-Tap.**
754. **MediaPipe Hands.**
755. **Overlay CAMetalLayer.**
756. **LiDAR.**
757. **Continuity 15-fps Probe** (inputPriority sitzt, Leiter 720p24 bleibt).
758. **Mission-Control Spread.**
759. **Two-pointer origin lock.**
760. **Pinch-Hysterese palmWidth.**
761. **Gesture-Macro.**
762. **SpaceMap nur als Start.**
763. **CGEvent tapHold.**
764. **pinch3DVeto Depth-Reach.**
765. **emptyHandsRecover(elapsed:)** Fold.
766. **SpaceMap Recenter nach Wake.**
767. **ROI-Hysterese 2 Frames.**
768. **formatPromoted nach inputPriority.** 720p24 → 1080p15.
769. **pinchHold analog Hysterese.**
770. **pinchClosedness EMA.**
771. **ROI scale 1,6** Continuity.
772. **ROI full jedes 4. Tick.**
773. **Cover-Lead Homographie Blend.**
774. **Bezel-Hop Blend** 200 ms.
775. **hudCoast Cap aus palmWidth.**
776. **Two-hand HUD-Lerp unabhängig.**

P0: CameraBroker. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.

# Helios Vorschläge — 2026-09-09 (Pass 42, 1.6.93)

Stand 1.6.93. inputPriority. analog 3D-nah Test.

## Gelandet in 1.6.93

- applySessionPreset: inputPriority vor 720/.high (Session + Cover)
- CoordTests analog-nah startet nicht ohne pinchClosed

## Erweiterung (neu)

705. **CameraBroker XPC + IOSurface** mit Aegis. P0.
706. **HeliosAegisKit.**
707. **VNTrackObjectRequest.** ROI sitzt — Track lohnt.
708. **Per-Finger-Kontakt.**
709. **HUD-Lerp zwischen Samples.**
710. **palmHighpass auf UV-Position.**
711. **Ampel-Ring Overlay.**
712. **Rechtsklick-HUD.**
713. **Click-Ring Overlay.**
714. **uniqueID persist nach Remint.**
715. **CGEventSource-State.**
716. **Desk-View Crop.**
717. **IOHIDEventSystemClient.**
718. **Watch Double-Tap.**
719. **MediaPipe Hands.**
720. **Overlay CAMetalLayer.**
721. **LiDAR.**
722. **Continuity 15-fps Probe** (inputPriority sitzt, Leiter 720p24 bleibt).
723. **Mission-Control Spread.**
724. **Two-pointer origin lock.**
725. **Pinch-Hysterese palmWidth.**
726. **Gesture-Macro.**
727. **SpaceMap nur als Start.**
728. **CGEvent tapHold.**
729. **pinch3DVeto Depth-Reach.**
730. **emptyHandsRecover(elapsed:)** Fold.
731. **SpaceMap Recenter nach Wake.**
732. **ROI-Hysterese 2 Frames.**
733. **formatPromoted nach inputPriority.** 720p24 → 1080p15.
734. **pinchHold analog Hysterese.**
735. **pinchClosedness EMA.**
736. **VNDetectHumanHandPoseRequest maximumHandCount 2.**
737. **ROI scale 1,6** Continuity.
738. **ROI full jedes 4. Tick.**
739. **Cover-Lead Homographie Blend.**
740. **Bezel-Hop Blend** 200 ms.

P0: CameraBroker. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.

# Helios Vorschläge — 2026-09-09 (Pass 41, 1.6.92)

Stand 1.6.92. Chirality live. AE reassert Wake.

## Gelandet in 1.6.92

- TrackedHand.chirality = slot.chirality
- reassertCaptureLocks Wake/Interrupt statt start()

## Erweiterung (neu)

670. **CameraBroker XPC + IOSurface** mit Aegis. P0.
671. **HeliosAegisKit.**
672. **VNTrackObjectRequest.** ROI sitzt — Track lohnt.
673. **Per-Finger-Kontakt.**
674. **HUD-Lerp zwischen Samples.**
675. **palmHighpass auf UV-Position.**
676. **Ampel-Ring Overlay.**
677. **Rechtsklick-HUD.**
678. **Click-Ring Overlay.**
679. **uniqueID persist nach Remint.**
680. **CGEventSource-State.**
681. **Desk-View Crop.**
682. **IOHIDEventSystemClient.**
683. **Watch Double-Tap.**
684. **MediaPipe Hands.**
685. **Overlay CAMetalLayer.**
686. **LiDAR.**
687. **Continuity 15-fps Probe.**
688. **Mission-Control Spread.**
689. **Two-pointer origin lock.**
690. **Pinch-Hysterese palmWidth.**
691. **Gesture-Macro.**
692. **SpaceMap nur als Start.**
693. **CGEvent tapHold.**
694. **pinch3DVeto Depth-Reach.**
695. **emptyHandsRecover(elapsed:)** Fold.
696. **SpaceMap Recenter nach Wake.**
697. **ROI-Hysterese 2 Frames.**
698. **Continuity Format/FPS nach Interrupt.**
699. **pinchClosedness EMA.**
700. **VNDetectHumanHandPoseRequest maximumHandCount 2.**
701. **ROI scale 1,6** Continuity.
702. **ROI full jedes 4. Tick.**
703. **Cover-Lead Homographie Blend.**
704. **Bezel-Hop Blend** 200 ms.

P0: CameraBroker. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.

# Helios Vorschläge — 2026-09-09 (Pass 40, 1.6.91)

Stand 1.6.91. AE nach Start. ROI live. analogClosed nur Hold. Release-Block.

## Gelandet in 1.6.91

- applyCaptureLocks nach startRunning (Session + Cover)
- visionRoiEnabled true, HandTracker ROI ×3 / Drop full
- pinchStartsGrab Start ohne analogClosed
- pinchReleaseBlocks vor startOk

## Erweiterung (neu)

636. **CameraBroker XPC + IOSurface** mit Aegis. P0.
637. **HeliosAegisKit.**
638. **VNTrackObjectRequest.** P1.
639. **VNImageRequestHandler(cvPixelBuffer:)** ohne CGImage.
640. **Per-Finger-Kontakt** statt Skalar-Closedness.
641. **HUD-Lerp zwischen Samples** (now−prev)/span, nicht Sample→Sample.
642. **palmHighpass auf UV-Position** nicht nur Delta.
643. **Ampel-Ring Overlay** vor fireChrome.
644. **Rechtsklick-HUD** 0,32 s.
645. **Click-Ring Overlay** 80 ms vor Fire.
646. **Hand-ID uniqueID-Flicker** (chiralityLock sitzt, uniqueID nicht).
647. **CGEventSource-State** Steal.
648. **Desk-View Crop-Kompensation.**
649. **IOHIDEventSystemClient** Pointer.
650. **Watch Double-Tap.**
651. **MediaPipe Hands Fallback.**
652. **Overlay CAMetalLayer.**
653. **LiDAR DepthCapture.**
654. **Continuity 15-fps Probe.**
655. **Mission-Control Spread.**
656. **Two-pointer origin lock.**
657. **Pinch-Hysterese palmWidth.**
658. **Gesture-Macro** 2-Schritt.
659. **SpaceMap nur als Start**, dann relativ.
660. **CGEvent tapHold** statt move+click.
661. **emptyHandsRecover(elapsed:)** Fold.
662. **Bezel-Hop Blend** 200 ms.
663. **Per-Display pointerGain.**
664. **axHitCacheFresh** AX nicht jedes Tick (SystemControl sitzt, Engine?).
665. **Idle-Palm dwell** 400 ms nach Dropout.
666. **ROI full jedes 4. Tick** zweite Hand einfangen.
667. **Cover-Lead Homographie Blend** useCover bleibt false.
668. **pinch3DVeto Depth-Reach** in driveGrab extra.
669. **Vision uniqueID** statt chiralityLock allein.

P0: CameraBroker. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.

# Helios Vorschläge — 2026-09-09 (Pass 39, 1.6.90)

Stand 1.6.90. AE/WB-Lock Phone, Center Stage aus.

## Gelandet in 1.6.90

- cameraLocksExposure / cameraLocksWhiteBalance in CameraSession + Cover
- centerStageNeedsReassert live (App-Modus, dann aus)

## Erweiterung (neu)

605. **CameraBroker XPC + IOSurface** mit Aegis. P0.
606. **HeliosAegisKit.**
607. **VNTrackObjectRequest.** P1.
608. **VNImageRequestHandler(cvPixelBuffer:).**
609. **Per-Finger-Kontakt.**
610. **analogClosed Start härter.**
611. **HUD-Lerp zwischen Samples.**
612. **palmHighpass auf UV-Position.**
613. **Ampel-Ring Overlay.**
614. **Rechtsklick-HUD.**
615. **Tap-Cancel.**
616. **Click-Ring Overlay.**
617. **Hand-ID uniqueID-Flicker.**
618. **CGEventSource-State.**
619. **Desk-View Crop.**
620. **IOHIDEventSystemClient.**
621. **Watch Double-Tap.**
622. **MediaPipe Hands.**
623. **Overlay CAMetalLayer.**
624. **LiDAR.**
625. **Continuity 15-fps Probe.**
626. **Mission-Control Spread.**
627. **Two-pointer origin lock.**
628. **Pinch-Hysterese palmWidth.**
629. **Gesture-Macro.**
630. **SpaceMap nur als Start.**
631. **CGEvent tapHold.**
632. **pinch3DVeto Depth-Reach.**
633. **emptyHandsRecover(elapsed:)** Fold.
634. **visionRoiEnabled** Continuity 8 Hz.
635. **AE-Lock nach Sleep reassert.**

P0: CameraBroker. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.

# Helios Vorschläge — 2026-09-09 (Pass 38, 1.6.89)


Stand 1.6.89. Highpass nach Clutch. HUD-Coast am Sample-Dropout.

## Gelandet in 1.6.89

- palmHighpassDelta nach Clutch (DC trainiert LP nicht während STILL)
- HUD-Coast wenn now > next.at vom Sample
- Tests + MARKETING 1.6.89 (Build 122)

## Erweiterung (neu)

574. **CameraBroker XPC + IOSurface** mit Aegis. P0.
575. **HeliosAegisKit.**
576. **VNTrackObjectRequest.** P1.
577. **VNImageRequestHandler(cvPixelBuffer:).**
578. **Per-Finger-Kontakt.**
579. **analogClosed Start härter.**
580. **HUD-Lerp zwischen Samples.**
581. **palmHighpass auf UV-Position.**
582. **Ampel-Ring Overlay.**
583. **Rechtsklick-HUD.**
584. **Tap-Cancel.**
585. **Click-Ring Overlay.**
586. **Hand-ID uniqueID-Flicker.**
587. **CGEventSource-State.**
588. **Desk-View Crop.**
589. **IOHIDEventSystemClient.**
590. **Watch Double-Tap.**
591. **MediaPipe Hands.**
592. **Overlay CAMetalLayer.**
593. **LiDAR.**
594. **Continuity 15-fps Probe.**
595. **Mission-Control Spread.**
596. **Two-pointer origin lock.**
597. **Pinch-Hysterese palmWidth.**
598. **Gesture-Macro.**
599. **SpaceMap nur als Start.**
600. **CGEvent tapHold.**
601. **pinch3DVeto.**
602. **axHitCacheFresh.**
603. **Per-Display pointerGain.**
604. **Bezel-Hop Blend.**

P0: CameraBroker. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.

# Helios Vorschläge — 2026-09-09 (Pass 37, 1.6.88)

Stand 1.6.88. palmHighpass / HUD-Coast / flingFromTrail / chiralityLock live.

## Gelandet in 1.6.88

- palmHighpassAlpha vor Gain (palmSlow LP der Screen-Deltas)
- hudCoastPoint nach t=1 (Cap scaled)
- flingFromTrail Fallback nach Vel-Tail
- chiralityLock am TrackSlot bei Dropout

## Erweiterung (neu)

539. **CameraBroker XPC + IOSurface** mit Aegis. Eine TCC. P0.
540. **HeliosAegisKit** SPM, Mutex einmal.
541. **VNTrackObjectRequest.** P1.
542. **VNImageRequestHandler(cvPixelBuffer:).**
543. **Per-Finger-Kontakt** statt Skalar.
544. **analogClosed Start härter.** analog 0,58 + pinchLooksLikePinch.
545. **Ampel-Ring Overlay** vor fireChrome.
546. **Rechtsklick-HUD** 0,32 s.
547. **Tap-Cancel** offene Palme 200 ms.
548. **Click-Ring Overlay** 80 ms vor Fire.
549. **CGEventSource-State** Steal.
550. **Desk-View Crop-Kompensation.**
551. **IOHIDEventSystemClient** Pointer.
552. **Watch Double-Tap.**
553. **MediaPipe Hands Fallback.**
554. **Overlay CAMetalLayer.**
555. **LiDAR DepthCapture.**
556. **Continuity 15-fps Probe.**
557. **Mission-Control Spread.**
558. **Aegis-Gaze Pinch-Confirm.**
559. **Gesture-Macro** 2-Schritt.
560. **Chrome-Dwell nur focused AX.**
561. **SpaceMap nur als Start.**
562. **CGEvent tapHold** statt move+click.
563. **axHitCacheFresh** AX nicht jedes Tick.
564. **emptyHandsRecover** extra Cap.
565. **HUD-Coast Vel EMA.**
566. **ChiralityLock + Palm-UV** bei doppeltem Flicker.
567. **Bezel-Hop Homographie Blend** 200 ms.
568. **Per-Display pointerGain Pref.**

P0: CameraBroker. Kein neues *Need(dt). Predict nicht wieder an. Branch `bugfix` nicht mergen.
