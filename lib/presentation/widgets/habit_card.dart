import 'package:flutter/material.dart';
import 'package:vive_good_app/domain/entities/user_habit.dart';
import 'common/responsive_dimensions.dart';

class HabitCard extends StatelessWidget {
  final UserHabit habit;
  final IconData iconData;
  final Color iconColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HabitCard({
    super.key,
    required this.habit,
    required this.iconData,
    required this.iconColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cardPadding = ResponsiveDimensions.getCardPadding(context);
    final borderRadius = ResponsiveDimensions.getBorderRadius(context);
    final iconSize =
        ResponsiveDimensions.getIconSize(context) *
        1.5; // Slightly larger for main icon
    final horizontalSpacing = ResponsiveDimensions.getHorizontalSpacing(
      context,
    );
    final titleFontSize = ResponsiveDimensions.getFontSize(
      context,
      type: 'title',
    );
    final subtitleFontSize = ResponsiveDimensions.getFontSize(
      context,
      type: 'subtitle',
    );
    final minHeight = ResponsiveDimensions.getCardMinHeight(context);

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: cardPadding,
        vertical: ResponsiveDimensions.getVerticalSpacing(context),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: 2.0,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          children: [
            Icon(iconData, color: iconColor, size: iconSize),
            SizedBox(width: horizontalSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    habit.habit?.name ?? 'No Name',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height:
                        ResponsiveDimensions.getVerticalSpacing(context) / 2,
                  ),
                  Text(
                    habit.habit?.description ?? 'No Description',
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.edit,
                size: ResponsiveDimensions.getIconSize(context),
              ),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(
                Icons.delete,
                size: ResponsiveDimensions.getIconSize(context),
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
