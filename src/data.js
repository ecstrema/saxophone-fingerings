export const saxMappings = {
  57: "s123456790bh", // A For baritone saxophone
  58: "s1234567bh",
  59: "s1234567b", // B
  60: "s1234567", // MIDDLE C (concert pitch)
  61: "s1234567v",
  62: "s123456", // D
  63: "s123456d",
  64: "s12345", // E
  65: "s1234", // F
  66: "s1235",
  67: "s123", // G
  68: "s123g",
  69: "s12", // A
  70: "s12a",
  71: "s1", // B
  72: "s2", // C
  73: "s",
  74: "s80123456", // D
  75: "s80123456d",
  76: "s8012345", // E
  77: "s801234", // F
  78: "s801235",
  79: "s80123", // G
  80: "s80123g",
  81: "s8012", // A
  82: "s8012a",
  83: "s801", // B
  84: "s802", // C
  85: "s80",
  86: "s80q", // D
  87: "s80qw",
  88: "s80qwe", // E
  89: "s80qwer", // F
  90: "s80qwert",
  91: "s8014ta", // G // HIGH REGISTER
  92: "s801234a",
  93: "s80234a", // A
  94: "s8034a",
  95: "s80q34a", // B
  96: "s80qw34a", // C
  97: "s80qwe34a",
  98: "s80x", // D
};

export const instrumentData = {
  "soprano sax": {
    transposition: 2,
    mappings: saxMappings,
  },
  "alto sax": {
    transposition: 9,
    mappings: saxMappings,
  },
  "tenor sax": {
    transposition: 14,
    mappings: saxMappings,
  },
  "barytone sax": {
    transposition: 21,
    mappings: saxMappings,
  },
};
