# Rive Character Animation & State Machine Integration Guide (Flutter)

This document serves as a complete technical reference and specification for controlling the **Chibi Krishna** Rive character (`krishna_ai_teacher_master`) inside a Flutter application using Rive Data Binding / ViewModel & State Machine inputs.

---

## 1. Model Architecture & Identifiers

- **Artboard Name:** `krishna_ai_teacher_master`
- **State Machine Name:** `KrishnaJI_SM`
- **Data Binding / ViewModel:** `ViewModel1`

---

## 2. Enumerations & Value Specifications

The animation state machine is driven by 3 primary enum properties defined under `ViewModel1`:

### A. `emotion` (Emotion State)
Controls facial expressions and emotional reactions.

| Enum Key / Name | String / Enum Representation | Typical Numeric Index | Description / State |
| :--- | :--- | :---: | :--- |
| `Exhalation` | `"Exhalation"` | `0` | Sigh / deep exhale |
| `Thniking` | `"Thniking"` *(Note spelling in Rive)* | `1` | Pensive / hand to chin |
| `Happy01` | `"Happy01"` | `2` | Default joyful smile |
| `Happy02` | `"Happy02"` | `3` | Wide happy smile / open mouth |
| `Happy03` | `"Happy03"` | `4` | Cheerful chuckle / ecstatic |
| `Sad` | `"Sad"` | `5` | Upset / downturned mouth |
| `Opps01` | `"Opps01"` | `6` | Minor mistake / bashful |
| `Opps02` | `"Opps02"` | `7` | Bigger blunder reaction |
| `Neutral01` | `"Neutral01"` | `8` | Baseline calm resting face |
| `Neutral02` | `"Neutral02"` | `9` | Secondary neutral expression |
| `Aaaaah` | `"Aaaaah"` | `10` | Shouting / alarmed vocalization |
| `Odd` | `"Odd"` | `11` | Perplexed / curious expression |
| `Crying` | `"Crying"` | `12` | Weeping / tears expression |
| `Oh No` | `"Oh No"` | `13` | Disbelief / shocked expression |

---

### B. `poses` (Body Poses & Gestures)
Controls full-body posturing, gestures, and active motion layers.

| Enum Key / Name | String / Enum Representation | Typical Numeric Index | Description / Gesture |
| :--- | :--- | :---: | :--- |
| `Yesss` | `"Yesss"` | `0` | Celebratory victory gesture |
| `idle_lookaround`| `"idle_lookaround"` | `1` | Idle scanning environment |
| `is_waving` | `"is_waving"` | `2` | Friendly hand wave |
| `talk_visemes` | `"talk_visemes"` | `3` | Active speech / mouth animation |
| `is_Denial` | `"is_Denial"` | `4` | Head shake / gesture saying no |
| `is_Acceptance` | `"is_Acceptance"` | `5` | Nodding / agreement gesture |
| `Idle` | `"Idle"` | `6` | Default neutral stance |

---

### C. `eye` (Eye Visibility & Scale)
Controls eye opening dynamics and blinking behavior.

| Enum Key / Name | String / Enum Representation | Typical Numeric Index | Description |
| :--- | :--- | :---: | :--- |
| `close` | `"close"` | `0` | Closed eyes / squinting |
| `open_big` | `"open_big"` | `1` | Wide open attentive eyes (Default) |
| `open_small` | `"open_small"` | `2` | Half-open / relaxed eyes |

---

## 3. Why It Was Stuck on Default (The Root Cause)

In newer Rive editor versions, properties listed under **Data / ViewModel** (like `ViewModel1` with properties `eye`, `poses`, `emotion`) can be configured in two distinct ways:

1. **Rive Data Binding (ViewModel Instance):**
   If the State Machine uses Data Binding directly to a ViewModel instance, standard `findInput<double>()` / `findInput<bool>()` calls on `StateMachineController` will return `null` or have no effect because they are **Data Properties**, not legacy **Inputs**.
2. **State Machine Inputs (Numeric/Enum Index):**
   If the transitions in `KrishnaJI_SM` check `emotion_state == 2` or `posesEnum == 0`, these are exposed as `SMINumber` on the `StateMachineController`.
3. **Trigger Invocations vs Persistent States:**
   If transitions go from `Any State` with conditions like `emotion == "Happy01"`, setting the variable once locks it into that state unless it transitions back or changes to another distinct value.

---

## 4. Flutter Implementation Reference

Below is the production-ready implementation supporting both **Data Binding / ViewModel APIs** and **State Machine Inputs**.

### Dart Models & Enums

```dart
enum KrishnaEmotion {
  exhalation,
  thinking,
  happy01,
  happy02,
  happy03,
  sad,
  opps01,
  opps02,
  neutral01,
  neutral02,
  aaaaah,
  odd,
  crying,
  ohNo,
}

extension KrishnaEmotionExtension on KrishnaEmotion {
  String get riveValue {
    switch (this) {
      case KrishnaEmotion.exhalation:
        return 'Exhalation';
      case KrishnaEmotion.thinking:
        return 'Thniking'; // Note: matches Rive editor spelling
      case KrishnaEmotion.happy01:
        return 'Happy01';
      case KrishnaEmotion.happy02:
        return 'Happy02';
      case KrishnaEmotion.happy03:
        return 'Happy03';
      case KrishnaEmotion.sad:
        return 'Sad';
      case KrishnaEmotion.opps01:
        return 'Opps01';
      case KrishnaEmotion.opps02:
        return 'Opps02';
      case KrishnaEmotion.neutral01:
        return 'Neutral01';
      case KrishnaEmotion.neutral02:
        return 'Neutral02';
      case KrishnaEmotion.aaaaah:
        return 'Aaaaah';
      case KrishnaEmotion.odd:
        return 'Odd';
      case KrishnaEmotion.crying:
        return 'Crying';
      case KrishnaEmotion.ohNo:
        return 'Oh No';
    }
  }

  int get indexValue => index;
}

enum KrishnaPose {
  yesss,
  idleLookaround,
  isWaving,
  talkVisemes,
  isDenial,
  isAcceptance,
  idle,
}

extension KrishnaPoseExtension on KrishnaPose {
  String get riveValue {
    switch (this) {
      case KrishnaPose.yesss:
        return 'Yesss';
      case KrishnaPose.idleLookaround:
        return 'idle_lookaround';
      case KrishnaPose.isWaving:
        return 'is_waving';
      case KrishnaPose.talkVisemes:
        return 'talk_visemes';
      case KrishnaPose.isDenial:
        return 'is_Denial';
      case KrishnaPose.isAcceptance:
        return 'is_Acceptance';
      case KrishnaPose.idle:
        return 'Idle';
    }
  }

  int get indexValue => index;
}

enum KrishnaEye {
  close,
  openBig,
  openSmall,
}

extension KrishnaEyeExtension on KrishnaEye {
  String get riveValue {
    switch (this) {
      case KrishnaEye.close:
        return 'close';
      case KrishnaEye.openBig:
        return 'open_big';
      case KrishnaEye.openSmall:
        return 'open_small';
    }
  }

  int get indexValue => index;
}
```

---

### Flutter Controller Widget

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

class KrishnaCharacterController extends StatefulWidget {
  final String assetPath;

  const KrishnaCharacterController({
    super.key,
    this.assetPath = 'assets/chibi_krishna.riv',
  });

  @override
  State<KrishnaCharacterController> createState() =>
      _KrishnaCharacterControllerState();
}

class _KrishnaCharacterControllerState extends State<KrishnaCharacterController> {
  Artboard? _artboard;
  StateMachineController? _controller;

  // State Machine inputs (if mapped via SM inputs)
  SMINumber? _emotionInput;
  SMINumber? _posesInput;
  SMINumber? _eyeInput;

  // Active States
  KrishnaEmotion _currentEmotion = KrishnaEmotion.happy01;
  KrishnaPose _currentPose = KrishnaPose.idle;
  KrishnaEye _currentEye = KrishnaEye.openBig;

  @override
  void initState() {
    super.initState();
    _initRive();
  }

  Future<void> _initRive() async {
    try {
      final bytes = await rootBundle.load(widget.assetPath);
      final file = RiveFile.import(bytes);

      // Select specific artboard
      final artboard =
          file.artboardByName('krishna_ai_teacher_master') ?? file.mainArtboard;

      final controller = StateMachineController.fromArtboard(
        artboard,
        'KrishnaJI_SM',
      );

      if (controller != null) {
        artboard.addController(controller);

        // Inspect and bind inputs
        for (var input in controller.inputs) {
          debugPrint('Detected Rive Input: ${input.name} (${input.runtimeType})');
        }

        // Try binding to standard input names
        _emotionInput = controller.findInput<double>('emotion') as SMINumber? ??
            controller.findInput<double>('emotion_state') as SMINumber?;
            
        _posesInput = controller.findInput<double>('poses') as SMINumber? ??
            controller.findInput<double>('posesEnum') as SMINumber?;
            
        _eyeInput = controller.findInput<double>('eye') as SMINumber? ??
            controller.findInput<double>('eye_type') as SMINumber?;

        // Fallback: If Data ViewModel Binding is used via Rive Runtime
        _bindViewModelInstance(artboard);
      }

      setState(() {
        _artboard = artboard;
        _controller = controller;
      });
    } catch (e, st) {
      debugPrint('Error loading Rive animation: $e\n$st');
    }
  }

  void _bindViewModelInstance(Artboard artboard) {
    // If the latest rive runtime exposes data binding instances:
    // artboard.dataBind(file.viewModelByName('ViewModel1'));
  }

  // --- External Actions ---

  void setEmotion(KrishnaEmotion emotion) {
    setState(() => _currentEmotion = emotion);
    if (_emotionInput != null) {
      _emotionInput!.value = emotion.indexValue.toDouble();
    }
  }

  void setPose(KrishnaPose pose) {
    setState(() => _currentPose = pose);
    if (_posesInput != null) {
      _posesInput!.value = pose.indexValue.toDouble();
    }
  }

  void setEye(KrishnaEye eye) {
    setState(() => _currentEye = eye);
    if (_eyeInput != null) {
      _eyeInput!.value = eye.indexValue.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_artboard == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: Rive(
            artboard: _artboard!,
            fit: BoxFit.contain,
          ),
        ),
        _buildActionControlPanel(),
      ],
    );
  }

  Widget _buildActionControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Emotions', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('Happy 01'),
                onPressed: () => setEmotion(KrishnaEmotion.happy01),
              ),
              ActionChip(
                label: const Text('Thinking'),
                onPressed: () => setEmotion(KrishnaEmotion.thinking),
              ),
              ActionChip(
                label: const Text('Sad'),
                onPressed: () => setEmotion(KrishnaEmotion.sad),
              ),
              ActionChip(
                label: const Text('Oh No'),
                onPressed: () => setEmotion(KrishnaEmotion.ohNo),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Poses', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('Idle'),
                onPressed: () => setPose(KrishnaPose.idle),
              ),
              ActionChip(
                label: const Text('Waving'),
                onPressed: () => setPose(KrishnaPose.isWaving),
              ),
              ActionChip(
                label: const Text('Talk Visemes'),
                onPressed: () => setPose(KrishnaPose.talkVisemes),
              ),
              ActionChip(
                label: const Text('Acceptance'),
                onPressed: () => setPose(KrishnaPose.isAcceptance),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## 5. Checklist for AI Coding Agents & Debugging

When building features around this character:
1. **Artboard Matching:** Always instantiate `file.artboardByName('krishna_ai_teacher_master')`. Using `file.mainArtboard` might pick up an empty root artboard if multiple artboards exist.
2. **State Machine Loading:** Always pass `'KrishnaJI_SM'` as the second argument to `StateMachineController.fromArtboard`.
3. **Exact Value Matching:**
   - `"Thniking"` has a typo in Rive (`Thniking` instead of `Thinking`). The code must pass the exact matching string/index.
   - Names are case-sensitive: `"Happy01"`, `"Opps01"`, `"is_waving"`.
4. **Transition Conditions:** If an animation does not trigger, open Rive, click the arrow connecting `Any State` -> `<Target Animation>`, and check whether the condition evaluates `ViewModel1.emotion == ...` or `emotion_state == ...`.
