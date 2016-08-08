public class Encode {
  final int W = 5;
  final int SIZE = W*W;
  final float MIN_LEN = 0.0001;
  final int TYPE = 2;

  float [] features;
  Grid [] grids;
  float nStrokes;
  XML xml;
  float factor;
  PVector bound1;
  PVector bound2;

  public Encode() {
    nStrokes = 0;
    factor = 16.0;
    features = new float[SIZE*TYPE+1];
    for (int i=0; i<features.length; i++) {
      features[i] = 0.0;
    }
    grids = new Grid[SIZE];
    for (int i=0; i<grids.length; i++) {
      grids[i] = new Grid();
    }
    bound1 = new PVector(Float.MAX_VALUE, Float.MAX_VALUE);
    bound2 = new PVector(Float.MIN_VALUE, Float.MIN_VALUE);
  }

  int getLength() {
    return features.length;
  }

  void getBounds() {
    bound1.set(Float.MAX_VALUE, Float.MAX_VALUE);
    bound2.set(Float.MIN_VALUE, Float.MIN_VALUE);

    XML [] strokes = xml.getChildren("stroke");
    for (XML st : strokes) {
      XML [] pts = st.getChildren("point");
      for (XML p : pts) {
        float x = p.getChild("x").getFloatContent();
        float y = p.getChild("y").getFloatContent();
        if (x < bound1.x) {
          bound1.x = x;
        }
        if (y < bound1.y) {
          bound1.y = y;
        }
        if (x > bound2.x) {
          bound2.x = x;
        }
        if (y > bound2.y) {
          bound2.y = y;
        }
      }
    }
  }

  PVector getNorm(PVector v) {
    float xRng = bound2.x - bound1.x;
    float yRng = bound2.y - bound1.y;
    // to cater for non-square bounding box.
    PVector offset = new PVector(0, 0);
    float xScale = 1.0, yScale = 1.0;
    if (xRng > yRng) {
      yScale = yRng / xRng;
      offset.y = (xRng - yRng) / 2.0;
    } else {
      xScale = xRng / yRng;
      offset.x = (yRng - xRng) / 2.0;
    }
    float x = (v.x - bound1.x) / xRng;
    float y = (v.y - bound1.y) / yRng;
    x = x * xScale + offset.x;
    y = y * yScale + offset.y;
    return new PVector(x, y);
  }

  void procChar(String f) {
    nStrokes = 0;
    for (Grid g : grids) {
      g.reset();
    }
    xml = loadXML(f);
    getBounds();
    XML [] strokes = xml.getChildren("stroke");
    nStrokes = strokes.length;

    for (XML x : strokes) {
      XML [] pts = x.getChildren("point");
      if (pts.length < 2) 
        continue;
      for (int i=0; i<pts.length-1; i++) {
        float x1 = pts[i].getChild("x").getFloatContent();
        float y1 = pts[i].getChild("y").getFloatContent();
        PVector v1 = getNorm(new PVector(x1, y1));
        float x2 = pts[i+1].getChild("x").getFloatContent();
        float y2 = pts[i+1].getChild("y").getFloatContent();
        PVector v2 = getNorm(new PVector(x2, y2));
        accumAngles(v1, v2);
      }
    }
  }

  void accumAngles(PVector p1, PVector p2) {
    float step = 1.0/W;
    int x = constrain(floor(p1.x/step), 0, W-1);
    int y = constrain(floor(p1.y/step), 0, W-1);
    int idx = y*W+x;
    PVector v = PVector.sub(p2, p1);
    if (v.mag() > MIN_LEN) 
      grids[idx].accumAngles(v);
  }

  void prepareData() {
    float mn = Float.MAX_VALUE;
    float mx = Float.MIN_VALUE;
    for (Grid g : grids) {
      float v = g.angles.mag();
      if (v < mn) {
        mn = v;
      } 
      if (v > mx) {
        mx = v;
      }
    }
    float range = mx - mn;

    features[0] = nStrokes/10.0;

    for (int i=0; i<grids.length; i++) {
      //      grids[i].angles.normalize();
      float len = grids[i].angles.mag();
      len = (len - mn)/range;
      float ang = degrees(grids[i].angles.heading());
      if (ang < 0) {
        ang += 360;
      }
      features[i+1] = len;
      features[i+grids.length+1] = ang / 360.0;
    }
  }

  float [] getFeatures() {
    return features;
  }

  void drawChar(PVector o, float s) {
    XML [] strokes = xml.getChildren("stroke");
    pushStyle();
    noFill();
    stroke(255, 0, 0, 100);
    float step = 1.0/W;
    for (int i=1; i<W; i++) {
      line(0+o.x, i*step*s+o.y, 1*s+o.x, i*step*s+o.y);
      line(i*step*s+o.x, 0, i*step*s+o.x, 1*s+o.y);
    }
    stroke(0);
    for (XML x : strokes) {
      XML [] pts = x.getChildren("point");
      if (pts.length < 2) 
        continue;
      for (int i=0; i<pts.length-1; i++) {
        XML pt1 = pts[i];
        XML pt2 = pts[i+1];
        float x1 = pt1.getChild("x").getFloatContent();
        float y1 = pt1.getChild("y").getFloatContent();
        float x2 = pt2.getChild("x").getFloatContent();
        float y2 = pt2.getChild("y").getFloatContent();
        float w1 = pt1.getChild("w").getFloatContent();
        strokeWeight(w1*factor);
        line(x1*s+o.x, y1*s+o.y, x2*s+o.x, y2*s+o.y);
      }
    }
    popStyle();
  }

  void drawGrid(PVector o, float s) {
    float mx = Float.MIN_VALUE;
    float mn = Float.MAX_VALUE;
    for (Grid g : grids) {
      float v = g.angles.mag();
      if (v < mn) {
        mn = v;
      }
      if (v > mx) {
        mx = v;
      }
    }
    float rn = mx - mn;
    float step = s/W;
    pushStyle();
    noFill();
    for (int i=0; i<grids.length; i++) {
      int x = i % W;
      int y = i / W;
      float ang = grids[i].angles.heading();
      float x1 = x*step+o.x+step/2;
      float y1 = y*step+o.y+step/2;
      float rad = (grids[i].angles.mag()-mn)*(step/2)/rn;
      float x2 = x1 + rad*cos(ang);
      float y2 = y1 + rad*sin(ang);
      float x3 = x1 + rad*cos(ang+PI);
      float y3 = y1 + rad*sin(ang+PI);
      stroke(0);
      strokeWeight(3);
      line(x1, y1, x2, y2);
      stroke(100);
      strokeWeight(1);
      line(x1, y1, x3, y3);
    }
    popStyle();
  }
}