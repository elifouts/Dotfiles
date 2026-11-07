import QtQuick
import "../../common"

Button {
    property string glyph
    signal clicked()
    label: glyph
    onPressed: clicked()
}
