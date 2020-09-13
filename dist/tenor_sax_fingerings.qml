//=============================================================================
//  MuseScore
//  Music Composition & Notation
//
//  Note Names Plugin
//
//  Copyright (C) 2012 Werner Schweer
//  Copyright (C) 2013 - 2020 Joachim Schmitz
//  Copyright (C) 2014 Jörn Eichler
//  Copyright (C) 2020 Johan Temmerman
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2
//  as published by the Free Software Foundation and appearing in
//  the file LICENCE.GPL
//=============================================================================

import QtQuick 2.2
import MuseScore 3.0

MuseScore {
   version: "3.5"
   description: qsTr("This plugin adds tenor saxophone fingerings to your selection/the whole score")
   menuPath: "Plugins." + qsTr("saxophone fingerings") + "." + qsTr("tenor")

   // Small note name size is fraction of the full font size.
   property var fontSizeBig: 1.5;

   function pitchToText(pitch) {
      console.log(pitch)

      pitch = pitch + 14; // transpose to tenor saxophone
      switch(pitch){
         case 57: return '`123456cBA'  // A For baritone saxophone
         case 58: return '`123456cB'
         case 59: return '`123456cb'   // B
         case 60: return '`123456c'    // MIDDLE C (concert pitch)
         case 61: return '`123456cC'
         case 62: return '`123456'     // D
         case 63: return '`123456D'
         case 64: return '`12345'      // E
         case 65: return '`1234'       // F
         case 66: return '`1235'
         case 67: return '`123'        // G
         case 68: return '`123G'
         case 69: return '`12'         // A
         case 70: return '`12Tj'
         case 71: return '`1'          // B
         case 72: return '`2'          // C
         case 73: return '`'
         case 74: return '`8123456'    // D
         case 75: return '`8123456D'
         case 76: return '`812345'     // E
         case 77: return '`81234'      // F
         case 78: return '`81235'
         case 79: return '`8123'       // G
         case 80: return '`8123G'
         case 81: return '`812'        // A
         case 82: return '`812Tj'
         case 83: return '`81'         // B
         case 84: return '`82'         // C
         case 85: return '`8'
         case 86: return '`8q'         // D
         case 87: return '`8qw'
         case 88: return '`8qwe'       // E
         case 88: return '`8qwer'      // F
         case 89: return '`8qwert'
         case 90: return '`81.4Tj'     // G // HIGH REGISTER
         case 91: return '`81234Tj'
         case 91: return '`8234Tj'     // A
         case 92: return '`834Tj'
         case 93: return '`8q34Tj'     // B
         case 94: return '`8qw34Tj'    // C
         case 95: return '`8qwe34Tj'
         case 96: return '`8x'         // D

         default: return '?'
      }
   }

   function nameChord (notes, text, small) {
      for (var i = 0; i < notes.length; i++) {
         var sep = ",";   // change to "," if you want them horizontally (anybody?)
         if ( i > 0 )
            text.text = sep + text.text; // any but top note
         if (small)
             text.fontSize *= fontSizeBig
         if (typeof notes[i].tpc === "undefined") // like for grace notes ?!?
            return

         text.subStyle = Tid.USER10;
         text.fontFace = "Woodwind Tablature Sax Euro";
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
}
