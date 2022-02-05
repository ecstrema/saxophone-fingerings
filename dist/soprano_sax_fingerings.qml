import QtQuick 2.2
import MuseScore 3.0
import QtQuick.Dialogs 1.1

MuseScore {
   version: "3.5"
   description: qsTr("This plugin adds soprano saxophone fingerings to your selection/the whole score")
   menuPath: "Plugins." + qsTr("saxophone fingerings") + "." + qsTr("soprano")

   // Small note name size is fraction of the full font size.
   property var fontSizeBig: 0.8;

   function pitchToText(pitch) {
      console.log(pitch)

      pitch = pitch + 2; // transpose to soprano saxophone
      switch(pitch){
         case 57: return 's123456790bh'  // A For baritone saxophone
         case 58: return 's1234567bh'
         case 59: return 's1234567b'   // B
         case 60: return 's1234567'    // MIDDLE C (concert pitch)
         case 61: return 's1234567v'
         case 62: return 's123456'     // D
         case 63: return 's123456d'
         case 64: return 's12345'      // E
         case 65: return 's1234'       // F
         case 66: return 's1235'
         case 67: return 's123'        // G
         case 68: return 's123g'
         case 69: return 's12'         // A
         case 70: return 's12a'
         case 71: return 's1'          // B
         case 72: return 's2'          // C
         case 73: return 's'
         case 74: return 's80123456'    // D
         case 75: return 's80123456d'
         case 76: return 's8012345'     // E
         case 77: return 's801234'      // F
         case 78: return 's801235'
         case 79: return 's80123'       // G
         case 80: return 's80123g'
         case 81: return 's8012'        // A
         case 82: return 's8012a'
         case 83: return 's801'         // B
         case 84: return 's802'         // C
         case 85: return 's80'
         case 86: return 's80q'         // D
         case 87: return 's80qw'
         case 88: return 's80qwe'       // E
         case 89: return 's80qwer'      // F
         case 90: return 's80qwert'
         case 91: return 's8014ta'     // G // HIGH REGISTER
         case 92: return 's801234a'
         case 93: return 's80234a'     // A
         case 94: return 's8034a'
         case 95: return 's80q34a'     // B
         case 96: return 's80qw34a'    // C
         case 97: return 's80qwe34a'
         case 98: return 's80x'         // D

         default: return '?'
      }
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
             text.fontSize *= fontSizeBig
         if (typeof notes[i].tpc === "undefined") // like for grace notes ?!?
            return

         text.text = pitchToText(notes[i].pitch) + text.text;
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
            switch (cursor.voice) {
               case 1: case 3: text.placement = Placement.BELOW; break;
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

   function work()   {
      var cursor = curScore.newCursor();
      var startStaff;
      var endStaff;
      var endTick;
      var fullScore = false;
      cursor.rewind(Cursor.SELECTION_START);
      if (!cursor.segment) { // no selection
         fullScore = true;
         startStaff = 0; // start with 1st staff
         endStaff  = curScore.nstaves - 1; // and end with last
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
      console.log(startStaff + " - " + endStaff + " - " + endTick)

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
                  var leadingLifo = new Array();   // List for leading grace notes
                  var trailingFifo = new Array();  // List for trailing grace notes
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

                  switch (cursor.voice) {
                     case 1: case 3: text.placement = Placement.BELOW; break;
                  }

                  text = newElement(Element.STAFF_TEXT) // Make another STAFF_TEXT object

                  // Finally process trailing grace notes if they exist...
                  text = renderGraceNoteNames(cursor, trailingFifo, text, true)
               } // end if CHORD
               cursor.next();
            } // end while segment
         } // end for voice
      } // end for staff
   } // end onRun

   MessageDialog {
      id : fontMissingDialog
      icon : StandardIcon.Warning
      standardButtons : StandardButton.Ok
      title : 'Missing Saxy font'
      text : 'This plugin needs the Saxy font to be installed from your device in order to work\n.'
      informativeText  : 'You can download it with this link:\n' +
      'https://github.com/Marr11317/Saxy/raw/master/redist/Saxy.ttf\n\n' +
      'and follow the standard procedure to install it on your device.\n' +
      'You will also need to restart MuseScore.\n' +
      'More information about this font is available here: https://github.com/Marr11317/Saxy'
   }
}
