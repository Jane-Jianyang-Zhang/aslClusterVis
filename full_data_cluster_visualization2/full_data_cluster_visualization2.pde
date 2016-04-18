import java.util.Arrays;
import java.util.*;
import processing.video.*;

BufferedReader reader;
String line;
int counter;
String [] features;
final float threshold = 0;
final int k = 4;
final int loc_x = 1000;
final int loc_y = 300;
Movie test;

int buttonClicked = 0;
PImage loc_color;
Set<ClusterButton> buttons = new HashSet<ClusterButton>();

Set<Integer> names = new TreeSet<Integer>();
Map<Integer, Set<String>> clusters = new TreeMap<Integer, Set<String>>();
Map<String, Integer> assignment = new TreeMap<String, Integer>();
Map<Integer, Set<Feature>> clusterToFeature = new TreeMap<Integer, Set<Feature>>();
ArrayList<Sign> signs = new ArrayList<Sign>();
ArrayList<Sign> signE = new ArrayList<Sign>();
ArrayList<Sign> signS = new ArrayList<Sign>();
Map<String, float[]> rawData = new TreeMap<String, float[]>();
Map<Integer, float[]> clusterCenters = new HashMap<Integer, float[]>();

void setup() {

  // set up of the screen
  size(1800, 1200);
  background(255);
  translate(10, height-10);
  scale(1, 1);
  stroke(0);
  readRawData();
  // This part read in the centeres for each cluster
  readCenters();
  //System.out.println(clusterToFeature.toString());
  // System.out.println();

  //This part read in the cluster assignemnt
  readClusters();
  //System.out.println(clusters.toString());

  //this part read the dimension reduction matrix reduced to 2 dimension
  readDimRedData("E");
  readDimRedData("S");
  

  loc_color= loadImage("Archive/locations/locationOutlined.png");
  signs = signE;
}

void draw() {

  background(255);
  names.clear();
  plotSigns();

  if (buttonClicked != 0) {
    int size = clusters.get(buttonClicked).size();
    fill(0);
    text("size: " + size, 1200, 150);
    showImage(buttonClicked);
  }

  for (ClusterButton button : buttons) {
    switch (button.cluster) {
    case 1:  
      fill(93, 165, 218, 170);
      break;
    case 2:  
      fill(241, 88, 84, 170);
      break;
    case 3:  
      fill(250, 164, 58, 170);
      break;
    case 4:  
      fill(96, 189, 104, 170);
      break;
    case 5:  
      fill(241, 124, 176, 170);
      break;
    case 6:  
      fill(0, 204, 204, 170);
      break;
    case 7:  
      fill(77, 25, 25, 170);
      break;
    case 8:  
      fill(153, 0, 204, 170);
      break;
    case 9:  
      fill(0, 0, 153, 170);
      break;
    case 10:  
      fill(179, 89, 0, 170);
      break;
    default: 
      fill(0, 100, 0, 170);
      break;
    }
    if (buttonClicked == button.cluster) {
      stroke(0);
    } else {
      stroke(255, 255, 255, 100);
    }
    rect(button.position.x, button.position.y, 90, 55, 7);
    fill(0, 0, 0);
    text("C " + button.cluster, button.position.x + 22, button.position.y + 37);
  }

  int y = 80;
  for (Integer name : names) {
    Sign e = signE.get(name);
    Sign s = signS.get(name);
    fill(150, 0, 120, 170);
    ellipse(s.coordinates.x, s.coordinates.y, 100 * s.confidence, 100 * s.confidence);
    ellipse(e.coordinates.x, e.coordinates.y, 100 * e.confidence, 100 * e.confidence);
    fill(0, 0, 0);
    text(s.name + " (s)", s.coordinates.x, s.coordinates.y - 20);
    text(e.name + " (e)", e.coordinates.x, e.coordinates.y - 20);
  }
  fill (255, 200, 0);
  rect(1520, 50, 120, 55, 7);
  
  rect(1650, 50, 120, 55, 7);
  fill(0, 0, 0);
  text("Expert", 1530, 90);
  text("Student", 1658, 90);
  if (test != null) {
    image(test, 1000, 200);
  }
} 

void movieEvent(Movie m) {
  m.read();
}

void loadVideo(String name) {
  test = new Movie(this, "mp4/" + name.substring(1, name.length() - 1) + ".mp4");
  test.loop();
}

void mouseClicked() {
  test = null;
  boolean clicked = false;
  for (ClusterButton button : buttons) {
    if (overButton(button)) {
      clicked = true;  
      buttonClicked = button.cluster;
    }
  }
  if (clicked == false) {
    buttonClicked = 0;
  }
  if (overRect(1520, 50, 90, 55)) {
    signs = signE;
  } else if (overRect(1650, 50, 90, 55)) {
    signs = signS;
  } 
  for (Sign s:signs) {
    if (overCircle(s.coordinates.x, s.coordinates.y, 100 * s.confidence)) {
        loadVideo(s.name);
      }
  }
}

void showImage(int cluster) {
  image(loc_color, loc_x, loc_y);
  Set<Feature> features = clusterToFeature.get(cluster);
  int i = 0;
  int j = 0;
  int y = 100;
  int x = 1200;
  String cur_type = "";
  int count = 0;
  for (Feature feature : features) {
    float freq = feature.freq;
    String name = feature.name;
    if (name.equals("one hand") || name.equals("two hands")) {
      fill(0);
      text( name, 1450, 150);
      text(freq, 1450, 180);
    } else {
      String feature_type = feature.type;
      if (!cur_type.equals(feature_type)) {
        cur_type = feature_type;
        count = 0;
        j+=1;
        i = 0;
        if (feature_type.equals("loc")) {
          j--;
        }
      } else if (count > 4) {
        continue;
      } else {
        i += 1;
      }
      count++;
      if (feature_type.equals("hs")) {
        feature_type = "handshapes";
      } else if (feature_type.equals("loc")) {
        // System.out.println("loc");
        feature_type = "locations";
      } else if (feature_type.equals("mov") || feature_type.equals("relmov")) {
        feature_type = "movements (including relative)";
        name = "movements_" + name;
      } else if (feature_type.equals("or")) {
        feature_type = "orientations";
        name = "orientations_" + name;
      } else if (feature_type.equals("relpos")) {
        feature_type = "relative positions";
        name = "relations_" + name;
      } else {
        // System.out.println(feature_type);
      }
      if (feature_type.equals("locations")) {
        fill(255 - freq * 255, 255  -  freq * 100, 255, 170);
        textSize(20);
        if (name.equals("upperface")) {
          displayLocation(loc_x + 121, loc_y + 29, 53, 24, freq, name);
        } else if (name.equals("midface")) {
          displayLocation(loc_x + 120, loc_y + 55, 57, 10, freq, name);
        } else if (name.equals("sideface")) {
          displayLocation(loc_x + 118, loc_y + 67, 59, 30, freq, name);
        } else if (name.equals("lowerface")) {
          displayLocation(loc_x + 121, loc_y + 91, 51, 15, freq, name);
        } else if (name.equals("neck")) {
          displayLocation(loc_x + 128, loc_y + 105, 49, 21, freq, name);
        } else if (name.equals("trunk")) {
          displayLocation(loc_x + 71, loc_y + 143, 161, 191, freq, name);
        } else if (name.equals("upperarm")) {
          displayLocation(loc_x + 220, loc_y + 168, 40, 84, freq, name);
        } else if (name.equals("lowerarm")) {
          displayLocation(loc_x + 219, loc_y + 264, 64, 76, freq, name);
        } else if (name.equals("wristup")) {
          displayLocation(loc_x + 22, loc_y + 181, 20, 13, freq, name);
        } else if (name.equals("wristdown")) {
          displayLocation(loc_x + 27, loc_y + 279, 20, 22, freq, name);
        }
        fill(0);

        text(name, 1000 + (i % 3)* 120, 700 + (i / 3) * 60);
        text(String.format("%.2f", freq) + "",  1000 + (i % 3) * 120, 730 + (i / 3) * 60);
        textSize(28);
      } else {
        PImage img;
        if (feature_type.equals("handshapes")  ) {
          int underscore = name.indexOf('_');
          if (underscore != -1) {
            name = name.substring(0, 1).toUpperCase() + name.substring(1, name.length() - 1) + name.substring(name.length()-1).toUpperCase();
          } else {
            name = name.toUpperCase();
          }
          img = loadImage("Archive/" + feature_type + "/" + name + ".JPG");
        } else {
          img = loadImage("Archive/" + feature_type + "/" + name + ".jpg");
        }
        fill(255 - freq * 255, 255  -  freq * 100, 255, 170);
        rect(1350 + i * 80, j * 140 + y - freq * 70 - 10, 60, freq * 70);


        fill(96, 189, 104, 170);

        if (feature_type.equals("handshapes")) {
          if (overRect(1350 + i * 80, j * 140 + y, img.width * 1/3, img.height * 1/3)) {
            fill(0, 0, 0);
            textSize(20);
            text(feature_type + "_" + name, 1355 + i * 80 - 40, j  * 140 + y + 100);
            text(String.format("%.2f", freq) + "", 1355 + i * 80, j * 140 + y - freq * 70 - 12);
            textSize(28);
            image(img, 1350 + i * 80, j * 140 + y, img.width * 0.35, img.height * 0.35);
          } else {
            image(img, 1350 + i * 80, j * 140 + y, img.width * 1/3, img.height *1/3);
          }
        } else {
          if (overRect(1350 + i * 80, j * 140 + y, img.width, img.height)) {
            fill(0, 0, 0);
            image(img, 1350 + i * 80 - 5, j * 140 + y - 5, img.width * 1.2, img.height * 1.2);
            textSize(20);
            text(name, 1355 + i * 80 - 40, j  * 140 + y + 100);
            text(String.format("%.2f", freq) + "", 1355 + i * 80, j * 140 + y - freq * 70 - 12);
            textSize(28);
          } else {
            image(img, 1350 + i * 80, j * 140 + y, img.width, img.height);
          }
        }
      }
    }
  }
}

void displayLocation(int x, int y, int width, int height, float freq, String name) {
  rect(x, y, width, height);
  if (overRect(x, y, width, height)) {
    textSize(28);
  }
}

boolean overButton(ClusterButton button) {
  return (mouseX > button.position.x && mouseX < button.position.x+90 && 
    mouseY > button.position.y && mouseY < button.position.y+55);
}

boolean overRect(int x, int y, int width, int height) {
  return (mouseX > x && mouseX < x+width && 
    mouseY >y && mouseY < y+height);
}

boolean overCircle(float x, float y, float diameter) {
  float disX = x - mouseX;
  float disY = y - mouseY;
  if (sqrt(sq(disX) + sq(disY)) < diameter/2 ) {
    return true;
  } else {
    return false;
  }
}

public void loadImages(String url, int x, int y) {
}

public void plotSigns() {
  for (int i=0; i<signs.size() - 1; i++) {
    Sign sign = signs.get(i);


    switch (sign.cluster) {
    case 1:  
      fill(93, 165, 218, 170);
      break;
    case 2:  
      fill(241, 88, 84, 170);
      break;
    case 3:  
      fill(250, 164, 58, 170);
      break;
    case 4:  
      fill(96, 189, 104, 170);
      break;
    case 5:  
      fill(241, 124, 176, 170);
      break;
    case 6:  
      fill(0, 204, 204, 170);
      break;
    case 7:  
      fill(77, 25, 25, 170);
      break;
    case 8:  
      fill(153, 0, 204, 170);
      break;
    case 9:  
      fill(0, 0, 153, 170);
      break;
    case 10:  
      fill(179, 89, 0, 170);
      break;
    default: 
      fill(0, 100, 0, 170);
      break;
    }
    textSize(28);
    stroke(250, 250, 250);
    if (sign.cluster == buttonClicked || buttonClicked == 0 ) {
      ellipse(sign.coordinates.x, sign.coordinates.y, 100 * sign.confidence, 100 * sign.confidence);
      if (overCircle(sign.coordinates.x, sign.coordinates.y, 100 * sign.confidence)) {
        fill(0, 0, 0);
        text(sign.name, sign.coordinates.x, sign.coordinates.y - 20);
        names.add(i);
      }
    }
  }
}

// read the centers of the cluster
public void readCenters() {
  reader = createReader("/centers/full_data_center_" + k + ".tsv"); 
  counter = 0;
  do {
    try {
      line = reader.readLine();
    } 
    catch (IOException e) {
      e.printStackTrace();
      line = null;
    }
    if (line == null) {
      // Stop reading because of an error or file is empty
      noLoop();
    } else {
      String[] pieces = split(line, TAB);
      if (counter == 0) {
        features = pieces;
        // System.out.println(Arrays.toString(pieces));
      } else {
        int cluster = counter;
        buttons.add(new ClusterButton(new PVector(1000 + cluster * 100, 50), cluster));
        float [] fea = new float [pieces.length];
        for (int i = 1; i < pieces.length -1; i++) {
          float freq = Float.parseFloat(pieces[i]);
          fea[i - 1] = freq;
          if (freq > threshold) {
            String name = features[i - 1];
            String new_name = "";
            String type = "";
            if (name.equals("\"numHands\"")) {
              if (Float.parseFloat(pieces[i]) > 1.5) {
                new_name = "two hands";
              } else {
                new_name = "one hand";
              }
            } else {
              int pos = name.indexOf('_');
              new_name = name.substring(pos + 1, name.length()-1);
              type = name.substring(1, pos - 1);
              if (type.equals("relpo")) {
                type += "s";
              } else if (type.equals("relmo")) {
                type += "v";
              }
            }
            Feature new_feature = new Feature(freq, new_name, type);
            if (!clusterToFeature.containsKey(cluster)) {
              clusterToFeature.put(cluster, new TreeSet<Feature>());
            }
            Set<Feature> featureSet = clusterToFeature.get(cluster);
            featureSet.add(new_feature);
            clusterToFeature.put(cluster, featureSet);
           
          clusterCenters.put(cluster, fea);
          }
        }
      }
      counter++;
    }
  } while (counter < k + 1);
  

}

// read the clusters assignment for each feature
public void readClusters() {
  reader = createReader("/cluster/sort_cluster_full_data_" + k + ".tsv"); 
  counter = 0;
  do {
    try {
      line = reader.readLine();
    } 
    catch (IOException e) {
      e.printStackTrace();
      line = null;
    }
    if (line == null) {
      System.out.println("its not reading");
      // Stop reading because of an error or file is empty
      noLoop();
    } else {
      String[] pieces = split(line, TAB);
      if (counter == 0) {
      } else {

        int cluster = Integer.parseInt(pieces[1]);
        String sign = pieces[0];

        assignment.put(sign, cluster);
        if (!clusters.containsKey(cluster)) {
          clusters.put(cluster, new TreeSet<String>());
        }
        Set<String> querySet = clusters.get(cluster);
        querySet.add(sign);
        clusters.put(cluster, querySet);
      }
      counter++;
    }
  } while (counter < 101);
}

// read dimention reduction matrix
public void readDimRedData(String who) {
  reader = createReader("dim_red_full_data_" + who +".tsv"); 
  counter = 0;
  do {
    try {
      line = reader.readLine();
    } 
    catch (IOException e) {
      e.printStackTrace();
      line = null;
    }
    if (line == null) {
      // Stop reading because of an error or file is empty
      noLoop();
    } else {
      String[] pieces = split(line, TAB);

      if (counter == 0) {
      } else {
        String sign = pieces[0];
        float x = Float.parseFloat(pieces[1]) * 14000 * 0.6 + 1250;
        float y = Float.parseFloat(pieces[2]) * 2000  + 500;
        PVector v = new PVector(x, y);

        Sign newSign = new Sign(sign, v, assignment.get(sign));
        if (who.equals("E")) {
          signE.add(newSign);
        } else {
          signS.add(newSign);
        }
      }
      counter++;
    }
  } while (counter < 101);
  //System.out.println();
}

public void readRawData() {
  reader = createReader("raw_data.tsv"); 
  counter = 0;
  do {
    try {
      line = reader.readLine();
    } 
    catch (IOException e) {
      e.printStackTrace();
      line = null;
    }
    if (line == null) {
      // Stop reading because of an error or file is empty
      noLoop();
    } else {
      String[] pieces = split(line, TAB);

      if (counter == 0) {
      } else {
        String sign = pieces[0];
        float [] features = new float [pieces.length];
        for (int i = 1; i < pieces.length -1; i++) {
          features[i - 1] = Float.parseFloat(pieces[i]);
        }
        rawData.put(sign, features);
      }
    }
    counter++;
  } while (counter < 101);
  
  //System.out.println(rawData);
}


class Sign {
  public String name;
  public PVector coordinates;
  public int cluster;
  public float confidence;

  public Sign(String name, PVector coordinates, int cluster) {
    this.name = name;
    this.coordinates = coordinates;
    this.cluster = cluster;

    double con = cosineSimilarity(clusterCenters.get(cluster), rawData.get(name));
    if (this.cluster == 3) {
      this.confidence = (float) con - 0.3;
    } else {
      this.confidence = (float) con - 0.4;
    }
  }
}

public static double cosineSimilarity(float[] vectorA, float[] vectorB) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < vectorA.length; i++) {
        dotProduct += vectorA[i] * vectorB[i];
        normA += Math.pow(vectorA[i], 2);
        normB += Math.pow(vectorB[i], 2);
    }   
    return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
}

class Feature implements Comparable<Feature> {
  public float freq;
  public String name;
  public String type;

  public Feature (float freq, String name, String type) {
    this.freq = freq;
    this.name = name;
    this.type = type;
  }

  public String toString() {
    return "[" + name + ", " + freq + ", " + type +"]";
  }

  public int compareTo(Feature compareFeature) {
    float that_freq= ((Feature) compareFeature).freq; 
    String that_type = ((Feature) compareFeature).type;
    if (that_type.compareTo(this.type) == 0) {
      if (that_freq - this.freq > 0) {
        return 1;
      } else {
        return -1;
      }
    } else {
      return that_type.compareTo(this.type);
    }
  }
}

class ClusterButton {
  public PVector position;
  public int cluster;

  public ClusterButton (PVector position, int cluster) {
    this.position = position;
    this.cluster = cluster;
  }
}