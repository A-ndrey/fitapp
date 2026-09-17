# FitApp

FitApp records reusable fitness and nutrition knowledge separately from the
user's activity history and personal preferences.

## Libraries

**Food Library**:
The user's reusable foods and recipes. Recipes may reference other entries in
the Food Library.
_Avoid_: Food history, meal log

**Training Library**:
The user's reusable exercises and training plans. Training plans reference
exercises in the Training Library.
_Avoid_: Workout history, workout log

## Activity

**Nutrition History**:
The record of consumed foods and recipes, including the nutritional snapshot
captured when each entry was logged.
_Avoid_: Food Library, meal catalog

**Active Workout**:
The single workout currently in progress, including its planned targets and
recorded sets.
_Avoid_: Training plan, completed workout

**Workout History**:
The record of completed workouts and their self-contained exercise results. A
completed workout remains meaningful when its source exercise or training plan
changes or is removed from the Training Library.
_Avoid_: Training Library, active workout

## Personalization

**Preferences**:
The user's appearance, language, measurement units, and daily nutrition
targets.
_Avoid_: Profile, account

## Ownership

**Guest Data**:
Libraries, activity, and preferences created without a signed-in account. Guest
Data remains locally separate, then merges into Account Data when the user
signs in; account entities win same-ID conflicts.
_Avoid_: Account Data, shared local data

**Account Data**:
Libraries, activity, and preferences owned by one signed-in account.
_Avoid_: Guest Data, global local data
