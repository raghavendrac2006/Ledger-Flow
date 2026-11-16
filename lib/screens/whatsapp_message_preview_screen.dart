import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/models/whatsapp_message_model.dart';
import '../core/services/whatsapp_message_service.dart';
import '../widgets/bento_card.dart';
import '../widgets/custom_toast.dart';

class WhatsAppMessagePreviewScreen extends StatefulWidget {
  final List<WhatsAppCustomerMessage> messages;
  final Function(String name, String phone)? onPhoneUpdated;

  const WhatsAppMessagePreviewScreen({
    super.key,
    required this.messages,
    this.onPhoneUpdated,
  });

  @override
  State<WhatsAppMessagePreviewScreen> createState() => _WhatsAppMessagePreviewScreenState();
}

class _WhatsAppMessagePreviewScreenState extends State<WhatsAppMessagePreviewScreen> {
  late List<WhatsAppCustomerMessage> _messages;
  late List<TextEditingController> _controllers;
  bool _isDispatchMode = false;
  int _currentDispatchIndex = 0;

  @override
  void initState() {
    super.initState();
    _messages = widget.messages;
    _controllers = _messages.map((m) => TextEditingController(text: m.finalMessage)).toList();
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncControllersToMessages() {
    for (int i = 0; i < _messages.length; i++) {
      _messages[i].customMessage = _controllers[i].text;
    }
  }

  void _showEditPhoneDialog(int index) {
    final msg = _messages[index];
    final controller = TextEditingController(text: msg.phoneNumber ?? "");
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                side: const BorderSide(color: Colors.black, width: 2.0),
              ),
              backgroundColor: Colors.white,
              title: Text(
                "ENTER PHONE NUMBER",
                style: AppTheme.headlineMd.copyWith(fontSize: 16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Customer: ${msg.customerName}",
                    style: AppTheme.labelBold.copyWith(color: AppTheme.primary),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    decoration: InputDecoration(
                      prefixText: "+91 ",
                      hintText: "10-digit mobile number",
                      errorText: errorText,
                      filled: true,
                      fillColor: AppTheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("CANCEL", style: AppTheme.labelBold.copyWith(color: AppTheme.outline)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                  ),
                  onPressed: () {
                    final normalized = WhatsAppMessageService.normalizeIndianPhoneNumber(controller.text.trim());
                    if (normalized == null) {
                      setDialogState(() {
                        errorText = "Enter a valid 10-digit Indian mobile number";
                      });
                      return;
                    }
                    final phone = controller.text.trim();
                    setState(() {
                      _messages[index] = _messages[index].copyWith(phoneNumber: phone);
                    });
                    widget.onPhoneUpdated?.call(msg.customerName, phone);
                    Navigator.pop(ctx);
                    CustomToast.showSuccess(context, "PHONE SAVED FOR ${msg.customerName.toUpperCase()}");
                  },
                  child: Text("SAVE NUMBER", style: AppTheme.labelBold.copyWith(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _launchCurrentWhatsApp() async {
    final msg = _messages[_currentDispatchIndex];
    final normalized = WhatsAppMessageService.normalizeIndianPhoneNumber(msg.phoneNumber);

    if (normalized == null) {
      CustomToast.showError(context, "PLEASE ENTER A VALID PHONE NUMBER FIRST");
      _showEditPhoneDialog(_currentDispatchIndex);
      return;
    }

    final messageText = _controllers[_currentDispatchIndex].text.trim().isNotEmpty
        ? _controllers[_currentDispatchIndex].text.trim()
        : msg.finalMessage;

    final success = await WhatsAppMessageService.launchWhatsApp(
      normalizedPhone: normalized,
      message: messageText,
    );

    if (!success && mounted) {
      CustomToast.showError(context, "COULD NOT OPEN WHATSAPP APPLICATION");
    }
  }

  void _markCurrentAsSent() {
    setState(() {
      _messages[_currentDispatchIndex].status = WhatsAppDeliveryStatus.sent;
      if (_currentDispatchIndex < _messages.length - 1) {
        _currentDispatchIndex++;
      }
    });
  }

  void _skipCurrent() {
    setState(() {
      _messages[_currentDispatchIndex].status = WhatsAppDeliveryStatus.skipped;
      if (_currentDispatchIndex < _messages.length - 1) {
        _currentDispatchIndex++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(_isDispatchMode ? Icons.arrow_back : Icons.close, color: Colors.black),
          onPressed: () {
            if (_isDispatchMode) {
              setState(() {
                _isDispatchMode = false;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isDispatchMode ? "SENDING TO WHATSAPP" : "MESSAGE PREVIEW & EDIT",
              style: AppTheme.headlineMd.copyWith(fontSize: 17, letterSpacing: 1.0),
            ),
            Text(
              _isDispatchMode
                  ? "Open chats and send prefilled message"
                  : "${_messages.length} messages prepared",
              style: AppTheme.labelSm.copyWith(color: AppTheme.onSurfaceVariant),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppTheme.outlineVariant, height: 1.0),
        ),
      ),
      body: SafeArea(
        child: _isDispatchMode ? _buildDispatchView() : _buildPreviewListView(),
      ),
    );
  }

  // 1. PREVIEW & EDIT LIST VIEW
  Widget _buildPreviewListView() {
    return Column(
      children: [
        // Informational banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          color: AppTheme.primaryContainer,
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppTheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "You can review or edit each message before opening WhatsApp. WhatsApp will be opened chat-by-chat.",
                  style: AppTheme.bodyMd.copyWith(fontSize: 12, color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: _messages.length,
            separatorBuilder: (context, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final hasValidPhone = WhatsAppMessageService.isValidIndianPhoneNumber(msg.phoneNumber);

              return BentoCard(
                padding: const EdgeInsets.all(16.0),
                backgroundColor: Colors.white,
                border: Border.all(color: AppTheme.outlineVariant),
                shadowStyle: ShadowStyle.light,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Customer Name & Tags
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            msg.customerName,
                            style: AppTheme.headlineMd.copyWith(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: msg.isPaid ? AppTheme.successContainer : AppTheme.errorContainer,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: Text(
                            msg.isPaid ? "PAID" : "PENDING",
                            style: AppTheme.labelBold.copyWith(
                              color: msg.isPaid ? AppTheme.onSuccessContainer : AppTheme.onErrorContainer,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Amount & Phone Row
                    Row(
                      children: [
                        Text(
                          WhatsAppMessageService.formatCurrency(msg.todayAmount),
                          style: AppTheme.labelBold.copyWith(fontSize: 14, color: AppTheme.onSurface),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => _showEditPhoneDialog(index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: hasValidPhone ? AppTheme.surfaceContainerLow : AppTheme.tertiaryFixed,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: hasValidPhone ? AppTheme.outlineVariant : AppTheme.onTertiaryFixedVariant,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hasValidPhone ? Icons.phone : Icons.phone_missed,
                                  size: 13,
                                  color: hasValidPhone ? AppTheme.primary : AppTheme.onTertiaryFixedVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  hasValidPhone ? msg.phoneNumber! : "MISSING PHONE",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: hasValidPhone ? AppTheme.onSurface : AppTheme.onTertiaryFixedVariant,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit, size: 11, color: AppTheme.outline),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Editable Message Text Field
                    Text(
                      "MESSAGE TO CUSTOMER",
                      style: AppTheme.labelBold.copyWith(fontSize: 10, color: AppTheme.onSurfaceVariant, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _controllers[index],
                      maxLines: 4,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          borderSide: const BorderSide(color: AppTheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          borderSide: const BorderSide(color: AppTheme.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                        ),
                      ),
                      style: AppTheme.bodyMd.copyWith(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 6),

                    // Reset button if edited
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          _controllers[index].text = msg.defaultMessage;
                          setState(() {});
                        },
                        icon: const Icon(Icons.restore, size: 14, color: AppTheme.outline),
                        label: Text(
                          "RESET TEMPLATE",
                          style: AppTheme.labelSm.copyWith(color: AppTheme.outline, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Bottom Action to Start Dispatching
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.outlineVariant, width: 1.0)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18.0),
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                elevation: 3,
              ),
              onPressed: () {
                _syncControllersToMessages();
                setState(() {
                  _isDispatchMode = true;
                  _currentDispatchIndex = 0;
                });
              },
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              label: Text(
                "START WHATSAPP DISPATCH (${_messages.length} CUSTOMERS)",
                style: AppTheme.labelBold.copyWith(
                  color: Colors.white,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 2. SEQUENTIAL DISPATCH VIEW
  Widget _buildDispatchView() {
    final currentMsg = _messages[_currentDispatchIndex];
    final progress = (_currentDispatchIndex + 1) / _messages.length;
    final hasValidPhone = WhatsAppMessageService.isValidIndianPhoneNumber(currentMsg.phoneNumber);
    final sentCount = _messages.where((m) => m.status == WhatsAppDeliveryStatus.sent).length;
    final skippedCount = _messages.where((m) => m.status == WhatsAppDeliveryStatus.skipped).length;
    final isLastCustomer = _currentDispatchIndex == _messages.length - 1;
    final allProcessed = _messages.every((m) => m.status != WhatsAppDeliveryStatus.pending);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "CUSTOMER ${_currentDispatchIndex + 1} OF ${_messages.length}",
                style: AppTheme.headlineMd.copyWith(fontSize: 16),
              ),
              Text(
                "${(_currentDispatchIndex + 1)} / ${_messages.length}",
                style: AppTheme.labelBold.copyWith(color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.surfaceContainerHigh,
            color: AppTheme.primary,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 20),

          // Session Stats Chips
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: AppTheme.onSuccessContainer),
                    const SizedBox(width: 4),
                    Text(
                      "$sentCount SENT",
                      style: AppTheme.labelBold.copyWith(color: AppTheme.onSuccessContainer, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.skip_next, size: 14, color: AppTheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      "$skippedCount SKIPPED",
                      style: AppTheme.labelBold.copyWith(color: AppTheme.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (currentMsg.status != WhatsAppDeliveryStatus.pending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: currentMsg.status == WhatsAppDeliveryStatus.sent
                        ? AppTheme.successContainer
                        : AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    currentMsg.status == WhatsAppDeliveryStatus.sent ? "MARKED SENT" : "SKIPPED",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: currentMsg.status == WhatsAppDeliveryStatus.sent
                          ? AppTheme.onSuccessContainer
                          : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Current Customer Focus Card
          BentoCard(
            padding: const EdgeInsets.all(20.0),
            backgroundColor: Colors.white,
            border: Border.all(color: AppTheme.primary, width: 2.0),
            shadowStyle: ShadowStyle.button,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryContainer,
                      radius: 22,
                      child: Text(
                        currentMsg.customerName.isNotEmpty ? currentMsg.customerName[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentMsg.customerName,
                            style: AppTheme.headlineMd.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            WhatsAppMessageService.formatCurrency(currentMsg.todayAmount),
                            style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: currentMsg.isPaid ? AppTheme.successContainer : AppTheme.errorContainer,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Text(
                        currentMsg.isPaid ? "PAID" : "PENDING",
                        style: AppTheme.labelBold.copyWith(
                          color: currentMsg.isPaid ? AppTheme.onSuccessContainer : AppTheme.onErrorContainer,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28, color: AppTheme.outlineVariant),

                // Phone Status
                Row(
                  children: [
                    Icon(
                      hasValidPhone ? Icons.phone : Icons.warning_amber_rounded,
                      color: hasValidPhone ? AppTheme.primary : AppTheme.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasValidPhone ? "Phone: ${currentMsg.phoneNumber}" : "Phone Number Missing!",
                      style: AppTheme.labelBold.copyWith(
                        color: hasValidPhone ? AppTheme.onSurface : AppTheme.error,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () => _showEditPhoneDialog(_currentDispatchIndex),
                      icon: const Icon(Icons.edit, size: 14),
                      label: Text(hasValidPhone ? "EDIT" : "ADD NUMBER"),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Pre-filled Message Display
                Text(
                  "PRE-FILLED MESSAGE:",
                  style: AppTheme.labelBold.copyWith(fontSize: 11, color: AppTheme.onSurfaceVariant, letterSpacing: 1.0),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppTheme.outlineVariant),
                  ),
                  child: Text(
                    _controllers[_currentDispatchIndex].text.trim().isNotEmpty
                        ? _controllers[_currentDispatchIndex].text.trim()
                        : currentMsg.finalMessage,
                    style: AppTheme.bodyMd.copyWith(fontSize: 13, height: 1.4),
                  ),
                ),
                const SizedBox(height: 24),

                // Primary WhatsApp Launcher Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                      backgroundColor: const Color(0xFF25D366), // WhatsApp Brand Green
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      elevation: 3,
                    ),
                    onPressed: _launchCurrentWhatsApp,
                    icon: const Icon(Icons.chat, color: Colors.white, size: 20),
                    label: Text(
                      "OPEN IN WHATSAPP",
                      style: AppTheme.headlineMd.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    "WhatsApp will open with this message prefilled. Send it manually and return.",
                    style: AppTheme.labelSm.copyWith(color: AppTheme.onSurfaceVariant, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Flow Action Buttons: MARK AS SENT / SKIP / NAVIGATION
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    side: const BorderSide(color: AppTheme.outline, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  onPressed: _skipCurrent,
                  icon: const Icon(Icons.skip_next, color: AppTheme.onSurfaceVariant),
                  label: Text(
                    "SKIP",
                    style: AppTheme.labelBold.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  onPressed: _markCurrentAsSent,
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: Text(
                    "MARK AS SENT",
                    style: AppTheme.labelBold.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Previous / Next Customer Navigation Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _currentDispatchIndex > 0
                    ? () {
                        setState(() {
                          _currentDispatchIndex--;
                        });
                      }
                    : null,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text("PREVIOUS CUSTOMER"),
              ),
              if (!isLastCustomer)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentDispatchIndex++;
                    });
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text("NEXT CUSTOMER"),
                )
              else if (allProcessed)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                  ),
                  onPressed: () {
                    CustomToast.showSuccess(context, "ALL MESSAGES PROCESSED!");
                    Navigator.pop(context);
                  },
                  child: Text(
                    "DONE ($sentCount SENT)",
                    style: AppTheme.labelBold.copyWith(color: Colors.white),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
