// All characters, with encoding from stroke direction
import java.io.FilenameFilter;
import java.io.File;
import java.util.Arrays;

final int NUM = 1000;
final int CLUSTER_CNT = 50;
final int CNT = 32;

File [] files;
Encode enc;
String fName;
int fIdx;
boolean start;
String [] chNames;
PrintWriter output;
PVector offset1;
PVector offset2;
int cell;

void setup() {
  size(960, 960);
  background(255);
  noStroke();
  smooth();

  chNames = new String[NUM];

  fIdx = 0;
  files = getFiles();
  Arrays.sort(files);
  println("Number of characters " + files.length);
  checkMissing(files);
  start = false;
  enc = new Encode();
  output = createWriter("charTrain.csv");
  cell = width/CNT;
  //  cell = width/2;
  offset1 = new PVector(cell, 0);
  offset2 = new PVector(0, 0);
}

void checkMissing(File [] fs) {
  for (int i=0; i<fs.length; i++) {
    String fn = fs[i].getName();
    int id = Integer.parseInt(fn.substring(0, 4));
    int j = i+1;
    if (j != id) {
      println("Missing character " + j);
    }
  }
}

void draw() {
  if (!start) {
    return;
  }
  if (fIdx >= files.length) {
    saveFrame("images/AllChars####.png");
    output.flush();
    output.close();
    exit();
  } else {
    File f = files[fIdx];
    println(f.getName());
    fName = f.getName().substring(0, f.getName().length()-4);
    chNames[fIdx] = fName.substring(5, 6);
    //   labels[fIdx] = Integer.parseInt(fName.substring(0, 4));
    enc.procChar(f.getName());
    enc.prepareData();
    addChar();
    //    background(255);
    int x = CNT - 1 - fIdx / CNT ;
    int y = fIdx % CNT;
    offset1.set(x*cell, y*cell);
    enc.drawGrid(offset1, cell);
    //    enc.drawChar(offset2, cell);
    //    saveFrame("images/" + fName + ".png");
    fIdx++;
  }
}

File [] getFiles() {
  File [] fs;
  File dir = new File(dataPath(""));
  fs = dir.listFiles(new FilenameFilter() {
    public boolean accept(File d, String n) {
      return n.toLowerCase().endsWith(".xml");
    }
  }
  );
  return fs;
}

void addChar() {
  float [] feat = enc.getFeatures();
  output.print(fName.substring(5, 6) + ",");
  for (int j=0; j<feat.length-1; j++) { 
    output.print(str(feat[j]) + ",");
  }
  output.println(feat[feat.length-1]);
}

void mousePressed() {
  start = true;
}