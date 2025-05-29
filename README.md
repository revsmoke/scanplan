# Create a 3D model of an interior room by guiding the user through an AR experience

Highlight physical structures and display text that guides a user to scan the shape of their physical environment using a framework-provided view.

For more information about the app and how it works, see
[Create a 3D model of an interior room by guiding the user through an AR experience]
(https://developer.apple.com/documentation/roomplan/create_a_3d_model_of_an_interior_room_by_guiding_the_user_through_an_ar_experience) in the
developer documentation.

## Export Accuracy

The app exports the captured space to both **USDZ** and **JSON** formats. To
provide architects with the most detailed reference possible, the export uses
`CapturedRoom.ExportOption.all`. This option includes the parametric data and the
raw mesh in the same USDZ file so downstream tools can choose the level of
precision they require.

## Setup
Run `./setup.sh` to automatically install build tools like `xcodebuild` and other dependencies using `apt-get`.
