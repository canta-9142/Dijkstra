// FiboHeapクラスのpop()が距離優先ではなくランダムに呼び出されるようにしたもの

import static processing.core.PApplet.*;

public class RandomHeap extends FiboHeap {
  public RandomHeap() {
    super();
  }

  @Override
  protected void setNewHead() {
    if (head == null) return;
    // できるだけあとに追加されたものが優先されるようにheadを決める
    // 全体の高さの1/4までは入り込んで取り出せるスタックみたいなイメージ
    double r = Math.random(); // rは0~1の少数
    int index = floor((float)Math.pow(r - 0.5, 2) / 1.5f * this.getN()); // n(ルートリストの数 = headを回転できる最大回数)の0~1/4の整数を指定
    for (int i = 0; i < index; i++) {
      head = head.left; // 追加されたタイミングが新しい順に見ていく
    }
  }
  @Override
  public void pop() {
    if (head == null) return;
    if (head == head.right) {
      head = null;
    } else {
      Node r = head.right;
      head.remove();
      head = r;
    }
    n--;
    return;
  }
  public int popRandom() {
    this.setNewHead();
    int top = this.head.index;
    this.pop();
    return top;
  }
}
