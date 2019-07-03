#import "RLYSettingsCommandMode.h"

NSString *RLYSettingsCommandModeToString(RLYSettingsCommandMode settingsCommandMode)
{
    switch (settingsCommandMode)
    {
        case RLYSettingsCommandModeAdd:
            return @"add";
        case RLYSettingsCommandModeDelete:
            return @"delete";
    }
}
