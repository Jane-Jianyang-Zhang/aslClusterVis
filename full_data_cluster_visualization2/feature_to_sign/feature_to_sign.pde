import java.util.Arrays;
import java.util.*;
import controlP5.*;

BufferedReader reader;
String line;
int counter;
final float threshold = 0;
final int loc_x = 1000;
final int loc_y = 300;

String []features;

String superType;
String superName;

ControlP5 cp5;

DropdownList featureMenu;
DropdownList featureMenu2;

PImage loc_color;
Map<Integer, Set<String>> clusters = new TreeMap<Integer, Set<String>>();
Set<String> result = new TreeSet<String>();
Set<String> names = new TreeSet<String>();
ArrayList<Sign> signs = new ArrayList<Sign>();
Map<String, float[]> rawData = new TreeMap<String, float[]>();
Map<String, List<String>> featureDict = new TreeMap<String, List<String>>();
String [] featureList = {"hs1", "hs2", "loc1", "loc2", "mov1", "mov2", "numHand", "or1", "or2", "relmov", "relpos"};
Map<String, Set<String>> featureToSign = new TreeMap<String, Set<String>>();
Map<String, Integer> assignment = new TreeMap<String, Integer>();
Map<Integer, float[]> clusterCenters = new HashMap<Integer, float[]>();
String [] feature;
void setup() {

  // set up of the screen
  size(1800, 1000, P3D);
  background(255);
  translate(10, height-10);
  scale(1, 1);
  stroke(0);
  readRawData();
  // This part read in the centeres for each cluster
  readCenters();
  //System.out.println(clusterToFeature.toString());
  System.out.println();

  //This part read in the cluster assignemnt
  readClusters();
  //System.out.println(clusters.toString());

  //this part read the dimension reduction matrix reduced to 2 dimension
  readDimRedData();
  //this part read the dimension reduction matrix reduced to 2 dimension

  
  cp5 = new ControlP5(this);
 
  // add a dropdownlist at position (100,100)
  DropdownList featureMenu= cp5.addDropdownList("type menu").setPosition(1000, 100).setSize(200,1000);
  cp5.setFont(new ControlFont(createFont("CenturyGothic", 20), 20));
  featureMenu.setItemHeight(35);
  featureMenu.setBarHeight(35);
  // add items to the dropdownlist
  Set<String> keys = featureDict.keySet();
  int i = 0;
  for (String key : keys) {
    featureMenu.addItem(key, i);
    i++;
  }
}

void draw() {

  background(255);
  names.clear();
  plotSigns();

  int y = 80;
  for (String name : names) {
    y += 30;
    text(name, 1000, y);
  }
} 


void mouseClicked() {
}


// read the clusters assignment for each feature
public void readClusters() {
  reader = createReader("../cluster/sort_cluster_full_data_4.tsv"); 
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


public void plotSigns() {
  for (int i=0; i< signs.size() - 1; i++) {
    Sign sign = signs.get(i);
    textSize(28);
    stroke(250, 250, 250);
    if (result.contains(sign.name)) {
      fill(255, 50, 50, 170);
    } else {
      fill(255,200,200,170);
    }
    ellipse(sign.coordinates.x, sign.coordinates.y, 100 * sign.confidence, 100 * sign.confidence);
    if (overCircle(sign.coordinates.x, sign.coordinates.y, 100 * sign.confidence)) {
      fill(0, 0, 0);
      text(sign.name, sign.coordinates.x, sign.coordinates.y - 20);
      names.add(sign.name);
    }
  }
}



// read the centers of the cluster
public void readCenters() {
  reader = createReader("../centers/full_data_center_4.tsv"); 
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
        System.out.println(Arrays.toString(pieces));
      } else {
        int cluster = counter;
       
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
          
           
          clusterCenters.put(cluster, fea);
          }
        }
      }
      counter++;
    }
  } while (counter < 5);
  

}

// read dimention reduction matrix
public void readDimRedData() {
  reader = createReader("../dim_red_full_data.tsv"); 
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
        signs.add(newSign);
      }
      counter++;
    }
  } while (counter < 101);
  System.out.println();
}

public void readRawData() {
  reader = createReader("../raw_data.tsv"); 
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
      if (counter == 0) {
        feature =  split(line, TAB);
        List<String> newFeatureSet = new ArrayList<String>();
        newFeatureSet.add("1");
        newFeatureSet.add("2");
        featureDict.put(feature[0].substring(1,8), newFeatureSet);
        for(int i = 1; i < feature.length -1; i++){
          int pos = feature[i].indexOf('_');
          String type = feature[i].substring(1,pos);
          String name = feature[i].substring(pos+1, feature[i].length() - 1);
          if (featureDict.containsKey(type)) {
            List<String> list = featureDict.get(type);
            list.add(name);
            featureDict.put(type, list);
          } else {
            newFeatureSet = new ArrayList<String>();
          newFeatureSet.add(name);
          featureDict.put(type, newFeatureSet);
          }   
        }
      } else {
        String[] pieces = split(line, TAB);
        String sign = pieces[0];
        float [] features = new float [pieces.length];
        for (int i = 1; i < pieces.length -1; i++) {
          features[i - 1] = Float.parseFloat(pieces[i]);
          if (features[i - 1] > 0) {
            if (featureToSign.containsKey(feature[i])) {
                Set<String> set = featureToSign.get(feature[i]);
                set.add(sign);
                featureToSign.put(feature[i], set);
            } else {
                Set<String> set = new TreeSet<String>();
                set.add(sign);
                featureToSign.put(feature[i], set);
            }
          }
        }
        rawData.put(sign, features);
      }
    }
    counter++;
  } while (counter < 101);
  System.out.println();
  System.out.println(featureToSign);
  System.out.println(Arrays.toString(feature));
  
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
    if (cluster == 3) {
       this.confidence = (float) con - 0.2;
    } else {
      this.confidence = (float) con - 0.3;
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
  public String name;
  public String type;

  public Feature (String name, String type) {
    this.name = name;
    this.type = type;
  }

  public String toString() {
    return "[" + name + ", "  + type +"]";
  }

  public int compareTo(Feature compareFeature) {
    String that_type = ((Feature) compareFeature).type;
    if (that_type.compareTo(this.type) == 0) {
      return 0;
    } else {
      return that_type.compareTo(this.type);
    }
  }
}

void controlEvent(ControlEvent theEvent) {
  // DropdownList is of type ControlGroup.
  // A controlEvent will be triggered from inside the ControlGroup class.
  // therefore you need to check the originator of the Event with
  // if (theEvent.isGroup())
  // to avoid an error message thrown by controlP5.

  if (theEvent.isGroup()) {
    // check if the Event was triggered from a ControlGroup
    System.out.println("event from group : "+theEvent.getGroup().getValue()+" from "+theEvent.getGroup());
  } 
  else if (theEvent.isController()) {
    
    System.out.println("event from controller : "+theEvent.getController().getValue()+" from "+theEvent.getController().toString() + "/");
    if (theEvent.getController().toString().equals("type menu [DropdownList]")) {
      int index = (int) theEvent.getController().getValue();
      featureMenu2 = cp5.addDropdownList("feature Menu").setPosition(1210, 100).setSize(200,1000);
      featureMenu2.setItemHeight(35);
      featureMenu2.setBarHeight(35);
      // add items to the dropdownlist
      superType = featureList[index];
      superName = "";
      List<String> keys = featureDict.get(superType);
      int i = 0;
      for (String key : keys) {
        featureMenu2.addItem(key, i);
        i++;
      }
    }
    if (theEvent.getController().toString().equals("feature Menu [DropdownList]")) {
      superName = featureDict.get(superType).get((int) theEvent.getController().getValue());
      String key = "\"" + superType + "_" + superName + "\"";
      if (featureToSign.containsKey(key)) {
         result = featureToSign.get(key);
      } else {
        println(featureToSign.keySet().contains(key));
        result = new TreeSet<String>();
      }
    }
  }
}
 