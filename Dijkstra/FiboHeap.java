// Fibonacci Heap
// ヒープ全体(クラス自身が持っているのは先頭ノードへの参照とノード数のみ。ヒープはノード同士のつながりで表現される。) 
// CDLLは双方向循環リストのこと

import java.util.List;
import java.util.ArrayList;

public class FiboHeap {
  private static final double LOG_PHI = 0.4812118251;

  protected Node head; // 根ノードのCDLLの先頭ノード
  protected int n;     // 全ノードの個数
  
  public FiboHeap() {
    this.head = null;
    this.n = 0;
  }
  public Node topNode() {return this.head;}
  public int topIndex() {if (head == null) return -1; return this.head.index;}
  public int getN() {return this.n;}

  // 根ノードのCDLLに追加する(親も子もいない状態)
  public void push(Node newNode) {
    if (head == null) {
      head = newNode;
    } else {
      head.insertLeft(newNode);
      if (newNode.totalCost() < head.totalCost()) {
        this.head = newNode;
      }
    }
    n++;
    return;
  }

  // 線形探索で新しいheadを見つける
  protected void setNewHead() {
    if (head == null) return;
    Node cur = head.right;
    Node temp = head;
    while (cur != head) {
      if (cur.totalCost() < temp.totalCost()) {
        temp = cur;
      }
      cur = cur.right;
    }
    head = temp;
    return;
  }
  
  // 同じdegreeの根ノードが根リストに存在しないように整理する
  // Fibonacci Heapの根幹部分
  // だいぶ前に書いたコードでどういう動作か説明できないし、これが効いてくるのはもっと大きなヒープを扱うときなので、今は使用していない。
  private void consolidate() {
    int arraySize = (int) Math.floor(Math.log(n) / LOG_PHI) + 2; 
    Node[] A = new Node[arraySize]; //次数iの根ノードをA[i]に格納する

    Node cur = head;
    Node next;
    do {
      next = cur.right;
      while (A[cur.degree] != null) {
        if (cur.totalCost() >= A[cur.degree].totalCost()) { // 入れ替える必要がない場合→curを子にくっつけて次のA[i]を見る
          A[cur.degree].insertChild(cur.remove());
          A[cur.degree].degree++;
          cur = A[cur.degree];
          A[cur.degree] = null;
        }
        else { // Aを更新する(curとA[i]を入れ替える必要がある)場合
          cur.insertChild(A[cur.degree]);
          A[cur.degree] = null;
          cur.remove();
          cur.degree++;
        }
      }
      A[cur.degree] = cur;
      cur = next;
    } while (cur != head);
  }

  // 最小ノードを取り出す 
  public void pop() {
    if (head == null) return;
    Node r = head.right;
    if (head == r) {
      head.peel(head);
      head.remove();
      head = null;
    } else {
      head.peel(head);
      head.remove();
      head = r;
      this.setNewHead();
      //this.consolidate();
    }
    n--;
    return;
  }
  
  // いわゆる"decreaseKey"
  // ダイクストラ用
  public boolean prioritize(Node x, int newDist) { //親の更新をする必要があるならtrueを返す
    if (newDist >= x.dist) return false; // 更新する必要がなければリターン
    x.dist = newDist;

    if (x.parent == null) { // 自身が根ノードならheadの更新だけしてリターン
      if (x.dist < head.dist) head = x;
      return true;
    }

    Node y = x.parent;
    if (x.dist >= y.dist) return true; // heap-propertyに違反しておらず切り離す必要がなければリターン

    // cut x from parent
    if (y.child == x) { // 親のchildが自身ならchildを更新してからremove()する必要がある(木が壊れるため)
      if (x.right == x) { // かつ単独ループであるなら(子が自分一人だけ)null
        y.child = null;
      } else { // 単独ループでない→childを右に1つずらす
        y.child = x.right;
      }
    }

    // 親から分離、ルートCDLLに追加
    y.degree--;
    x.remove();
    x.parent = null;
    x.mark = false;
    head.insertLeft(x);

    // cascading cut(markがfalseとなるまで親を遡ってカットしていく)
    while (y != null) {
      if(!y.mark) {
        y.mark = true;
        break;
      } else {
        Node z = y.parent;
        if (z == null) break;
        if (z.child == y) {
          z.child = null;
        } else {
          z.child = y.right;
        }
        z.degree--;
        y.remove();
        y.parent = null;
        y.mark = false;
        head.insertLeft(y);
        y = z;
      }
    }

    if (x.dist < head.dist) head = x;
    return true;
  }
  //A*用
  public boolean prioritize(Node x, int newDist, int newEst) {
    if (newDist + newEst >= x.totalCost()) return false; // 更新する必要がなければリターン
    x.dist = newDist;
    x.est = newEst;

    if (x.parent == null) { // 自身が根ノードならheadの更新だけしてリターン
      if (x.totalCost() < head.totalCost()) head = x;
      return true;
    }
    
    Node y = x.parent;
    if (x.totalCost() >= y.totalCost()) return true; // heap-propertyに違反しておらず切り離す必要がなければリターン

    // cut x from parent
    if (y.child == x) { // 親のchildが自身ならchildを更新してからremove()する必要がある(木が壊れるため)
      if (x.right == x) { // かつ単独ループであるなら(子が自分一人だけなら)null
        y.child = null;
      } else { // 単独ループでない→childを右に1つずらす
        y.child = x.right;
      }
    }

    // 親から分離、ルートCDLLに追加
    y.degree--;
    x.remove();
    x.parent = null;
    x.mark = false;
    head.insertLeft(x);

    // cascading cut(markがfalseとなるまで親を遡ってカットしていく)
    while (y != null) {
      if(!y.mark) {
        y.mark = true;
        break;
      } else {
        Node z = y.parent;
        if (z == null) break;
        if (z.child == y) {
          z.child = null;
        } else {
          z.child = y.right;
        }
        z.degree--;
        y.remove();
        y.parent = null;
        y.mark = false;
        head.insertLeft(y);
        y = z;
      }
    }

    if (x.totalCost() < head.totalCost()) head = x;
    return true;
  }
}
