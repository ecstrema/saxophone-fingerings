import QtQuick 2.2
import MuseScore 3.0
import QtQuick.Dialogs
import "data.js" as Data

MuseScore {
   version: "4.0"
   description: qsTr("This plugin adds fingerings to your selection or the whole score if nothing is selected")
   requiresScore: true
   menuPath: "Plugins." + qsTr("add fingerings...")
   categoryCode: "composing-arranging-tools"
   thumbnailName: "thumbnail.png"

   // Small note name size is fraction of the full font size.
   property var graceNoteRatio: 0.8;

   function pitchToText(pitch, instrumentName: str) {
      var instrumentData = data[instrument]
      // Transpose for the corresponding instrument
      pitch = pitch + instrumentData.transposition;

      if (pitch in instrumentData.mappings) {
         return instrumentData.mappings[pitch];
      }
      return '?'
   }

   function nameChord (notes, text, small) {
      for (var i = 0; i < notes.length; i++) {
         var sep = " ";   // change to "\n" if you want them vertically (anybody?)

         text.subStyle = Tid.USER10;
         text.fontFace = "Saxy";
         if ( i > 0 )
            text.text = sep + text.text; // any but top note
         text.fontSize = 30
         if (small)
             text.fontSize *= graceNoteRatio
         if (typeof notes[i].tpc === "undefined") // like for grace notes ?!?
            return

         text.text += pitchToText(notes[i].pitch);
      }  // end for note
   }

   function renderGraceNoteNames (cursor, list, text, small) {
      if (list.length > 0) {     // Check for existence.
         // Now render grace note's names...
         for (var chordNum = 0; chordNum < list.length; chordNum++) {
            // iterate through all grace chords
            var chord = list[chordNum];
            // Set note text, grace notes are shown a bit smaller
            nameChord(chord.notes, text, small)
            cursor.add(text)
            // X position the note name over the grace chord
            text.offsetX = chord.posX
            if (cursor.voice % 2 === 1) {
               text.placement = Placement.BELOW;
            }

            // If we consume a STAFF_TEXT we must manufacture a new one.
            text = newElement(Element.STAFF_TEXT);    // Make another STAFF_TEXT
         }
      }
      return text
   }

   onRun: {
      if (Qt.fontFamilies().indexOf('Saxy') < 0) {
         fontMissingDialog.open();
         return;
      }
      work();
   }

   function work() {
      curScore.startCmd();

      var cursor = curScore.newCursor();
      var startStaff;
      var endStaff;
      var endTick;
      var fullScore = false;
      cursor.rewind(Cursor.SELECTION_START);
      if (!cursor.segment) { // no selection
         fullScore = true;
         startStaff = 0; // start with 1st staff
         endStaff = curScore.nstaves - 1; // and end with last
      } else {
         startStaff = cursor.staffIdx;
         cursor.rewind(Cursor.SELECTION_END);
         if (cursor.tick === 0) {
            // this happens when the selection includes
            // the last measure of the score.
            // rewind(Cursor.SELECTION_END) goes behind the last segment (where
            // there's none) and sets tick=0
            endTick = curScore.lastSegment.tick + 1;
         } else {
            endTick = cursor.tick;
         }
         endStaff = cursor.staffIdx;
      }

      for (var staff = startStaff; staff <= endStaff; staff++) {
         for (var voice = 0; voice < 4; voice++) {
            cursor.rewind(Cursor.SELECTION_START); // beginning of selection
            cursor.voice    = voice;
            cursor.staffIdx = staff;

            if (fullScore)  // no selection
               cursor.rewind(Cursor.SCORE_START); // beginning of score
            while (cursor.segment && (fullScore || cursor.tick < endTick)) {
               if (cursor.element && cursor.element.type === Element.CHORD) {
                  var text = newElement(Element.STAFF_TEXT);      // Make a STAFF_TEXT

                  // First...we need to scan grace notes for existence and break them
                  // into their appropriate lists with the correct ordering of notes.
                  var leadingLifo = [];   // List for leading grace notes
                  var trailingFifo = [];  // List for trailing grace notes
                  var graceChords = cursor.element.graceNotes;
                  // Build separate lists of leading and trailing grace note chords.
                  if (graceChords.length > 0) {
                     for (var chordNum = 0; chordNum < graceChords.length; chordNum++) {
                        var noteType = graceChords[chordNum].notes[0].noteType
                        if (noteType === NoteType.GRACE8_AFTER || noteType === NoteType.GRACE16_AFTER ||
                              noteType === NoteType.GRACE32_AFTER) {
                           trailingFifo.unshift(graceChords[chordNum])
                        } else {
                           leadingLifo.push(graceChords[chordNum])
                        }
                     }
                  }

                  // Next process the leading grace notes, should they exist...
                  text = renderGraceNoteNames(cursor, leadingLifo, text, true)

                  // Now handle the note names on the main chord...
                  var notes = cursor.element.notes;
                  nameChord(notes, text, false);
                  cursor.add(text);

                  if (cursor.voice % 2 === 1) {
                     text.placement = Placement.BELOW;
                  }

                  text = newElement(Element.STAFF_TEXT) // Make another STAFF_TEXT object

                  // Finally process trailing grace notes if they exist...
                  text = renderGraceNoteNames(cursor, trailingFifo, text, true)
               }
               cursor.next();
            }
         }
      }

      curScore.endCmd()
      quit();
   }

   property var consoleText: ""

   MessageDialog {
      id : consoleDialog
      icon : StandardIcon.Warning
      standardButtons : StandardButton.Ok
      title : 'Missing Saxy font'
      text: consoleText
   }

   MessageDialog {
      id : fontMissingDialog
      icon : StandardIcon.Warning
      standardButtons : StandardButton.Ok
      title : 'Missing Saxy font'
      text : 'This plugin needs the Saxy font to be installed on your device in order to work\n.'
      informativeText  : 'You can download it with this link:\n' +
      'https://github.com/ecstrema/Saxy/releases\n\n' +
      'and follow the standard procedure to install it on your device.\n' +
      'You will also need to restart MuseScore.\n' +
      'More information about this font is available here: https://github.com/Marr11317/Saxy'
   }
}
