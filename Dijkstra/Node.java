// ノード(マス目)ひとつ
//CDLLは双方向循環リストのこと

import java.util.List;
import java.util.ArrayList;

public class Node {
  int dist;          // 優先度: 現時点での推定最短距離
  int est;          // A*用のゴールまでの推定距離
  
  Node parent;      // ヒープ上の親ノードへの参照
  Node child;       // 自分が持つ子ノードのうち最も左のノードへの参照
  Node left, right; // 同じ階層の兄弟ノードへの参照(双方向循環リスト)
  int degree;       // 子ノードの数(ランク)
  boolean mark;     // フィボナッチヒープは一度しか子を切り離せない。子をすでに切り離したかどうかを格納
                    // mark == false : 子を切り離すだけ
                    // mark == true  : 子を切り離した後自分も切り離す(カスケードカット)
  
  int index;        // marr上でのインデックスに対応
  Node prev;        // 経路上の自分の親ノード
  int state;        // 現在の状態を示す(-1:障害物 0:未発見 1:発見済み 2:訪問済み 3:最短経路)
  
  public class States {
    public static final int Blocked = -1;
    public static final int Undiscovered = 0;
    public static final int Discovered = 1;
    public static final int Visited = 2;
    public static final int Path = 3;
  }

  public Node(int index, boolean aSter, boolean generateMaze) {
    this.dist = Integer.MAX_VALUE;
    this.parent = null;
    this.child = null;
    this.left = this;
    this.right = this;
    this.degree = 0;
    this.mark = false;
    this.index = index;
    this.prev = null;
    if (generateMaze) this.state = Node.States.Blocked;
    else              this.state = Node.States.Undiscovered;
    if (aSter) this.est = Integer.MAX_VALUE;
    else       this.est = 0;
  }
  // 自身の左隣に任意のノードを挿入
  public void insertLeft(Node newNode) {
    if (newNode == null) {
        System.out.println("insertLeft: newNode is null");
        return;
    }
    newNode.left = this.left;
    newNode.right = this;
    this.left.right = newNode;
    this.left = newNode;
    return;
  }
  // 自身を自身が属するCDLLから取り外す
  public Node remove() {
    if (this.right != this) {
      this.left.right = this.right;
      this.right.left = this.left;
    }
    this.left = this;
    this.right = this;
    return this;
  }
  // 自身の子を全て他のCDLLに移す
  public void peel(Node head) {
    if (this.child != null) {
      while (this.child.right != this.child) {
        head.insertLeft(this.child.left.remove());
      }
      head.insertLeft(this.child);
      this.child.parent = null;
      this.child = null;
      this.degree = 0;
    }
    return;
  }
  // A*用
  public int totalCost() {
    return this.dist + this.est;
  }
  // 自身の子ノードにnewNodeを追加する
  public void insertChild(Node newNode) {
    if (this.child == null) {
      this.child = newNode;
    }
    else {
      this.child.insertLeft(newNode);
    }
    return;
  }
}
