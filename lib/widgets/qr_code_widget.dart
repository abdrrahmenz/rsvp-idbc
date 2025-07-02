import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final int padding;
  final Widget? embeddedImage;
  final double? embeddedImageSize;
  final String? label;

  const QrCodeWidget({
    Key? key,
    required this.data,
    this.size = 200,
    this.foregroundColor,
    this.backgroundColor,
    this.padding = 10,
    this.embeddedImage,
    this.embeddedImageSize,
    this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size + (padding * 2),
          height: size + (padding * 2),
          padding: EdgeInsets.all(padding.toDouble()),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: QrImageView(
            data: data,
            version: QrVersions.auto,
            size: size,
            backgroundColor: backgroundColor ?? Colors.white,
            foregroundColor: foregroundColor ?? Colors.black,
            errorStateBuilder: (context, error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: size * 0.3,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error generating QR Code',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: size * 0.06,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
            embeddedImage: embeddedImage != null
                ? AssetImage(embeddedImage as String)
                : null,
            embeddedImageStyle: QrEmbeddedImageStyle(
              size: Size(
                embeddedImageSize ?? size * 0.2,
                embeddedImageSize ?? size * 0.2,
              ),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ],
    );
  }
}

// QR Code Display Dialog
class QrCodeDialog extends StatelessWidget {
  final String data;
  final String? title;
  final String? subtitle;
  final double qrSize;

  const QrCodeDialog({
    Key? key,
    required this.data,
    this.title,
    this.subtitle,
    this.qrSize = 250,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            if (subtitle != null) ...[
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            QrCodeWidget(
              data: data,
              size: qrSize,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                data,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tutup'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement share functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur share akan segera hadir'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Bagikan'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void show(
    BuildContext context, {
    required String data,
    String? title,
    String? subtitle,
  }) {
    showDialog(
      context: context,
      builder: (_) => QrCodeDialog(
        data: data,
        title: title,
        subtitle: subtitle,
      ),
    );
  }
}