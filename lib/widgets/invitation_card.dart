import 'package:flutter/material.dart';
import '../models/invitation_model.dart';

class InvitationCard extends StatelessWidget {
  final Invitation invitation;
  final VoidCallback? onTap;
  final VoidCallback? onQRCodeTap;

  const InvitationCard({
    Key? key,
    required this.invitation,
    this.onTap,
    this.onQRCodeTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    IconData typeIcon;

    switch (invitation.invitationType) {
      case 'student':
        typeColor = Colors.blue;
        typeIcon = Icons.school;
        break;
      case 'guardian':
        typeColor = Colors.green;
        typeIcon = Icons.family_restroom;
        break;
      case 'general':
        typeColor = Colors.orange;
        typeIcon = Icons.people;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.person;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invitation.name ?? 'Nama tidak tersedia',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            invitation.typeLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: typeColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onQRCodeTap != null)
                    IconButton(
                      icon: const Icon(Icons.qr_code),
                      onPressed: onQRCodeTap,
                      tooltip: 'Lihat QR Code',
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Info
              if (invitation.phone != null) ...[
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      invitation.phone!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              if (invitation.studentName != null) ...[
                Row(
                  children: [
                    Icon(Icons.school, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mahasiswa: ${invitation.studentName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              // Status
              Row(
                children: [
                  Icon(
                    invitation.isCheckedIn
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    size: 16,
                    color: invitation.isCheckedIn ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    invitation.isCheckedIn
                        ? 'Sudah Check-in'
                        : 'Belum Check-in',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          invitation.isCheckedIn ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (invitation.checkedInAt != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• ${_formatTime(invitation.checkedInAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),

              // Barcode
              if (invitation.barcode.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_2, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        invitation.barcode,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}