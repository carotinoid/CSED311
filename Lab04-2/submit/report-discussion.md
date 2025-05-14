
1. Discussion
  A. Control Hazard가 발생하는 이유
만약 어떠한 조치도 취하지 않고 Pipelined CPU를 구현한 경우 control 문(Bxx, JAL, JALR)이 아닌경우에도 다음 PC는 항상 ID단계 (또는 그 이상)에서 나오기 때문에, 한 명령어마다 항상 한 번 이상 stall되어야 하는 문제가 있다. 이를 해결하기 위해서 Branch prediction 방법을 사용하였다. 저번 랩에서는 다음 PC를 항상 현재 PC에 4를 더한 값으로 예측하였음과 동시에 control 문이 없는 테스트만 진행하였으나, 이번 랩에서는 control문을 적절히 처리하도록 구현해야 한다.

  B. 어떻게 Branch prediction을 다루었는가?
Branch Prediction을 어떻게 하는지와 상관없이, 다음 로직을 구현해야한다. 모든 예측이 틀리더라도 적절하게 수행하여야 한다. (Gshare를 통해 Branch Prediction을 구현하였다)

    1. Branch Prediction이 맞는 경우: 그대로 진행한다.
    2. Branch Prediction이 틀린 경우: 이전에 잘못 예측함으로 인해서 실행되지 말았어야할 명령어를 취소한다. 즉, nop으로 만들기 위해 write 신호를 포함한 컨트롤 신호를 끈다.

구현상으로는 다음과 같다.
    1. 잘못 예측한 경우를 감지하고 `단계_pred_wrong` 와이어 변수를 통해 신호를 보낸다. 
    2. 이를 `BubbleGen`모듈에서 받고, `단계_is_bubble` 와이어를 통해 해당 단계를 nop로 만들라는 신호를 준다.
    3. 각 단계의 레지스터에서 `단계_is_bubble` 와이어 변수를 받으면 해당 단계에서 전달되는 대부분 컨트롤 신호를 0으로 처리한다.

  C. Gshare와 always taken, always not taken 사이클 수 비교
* **Gshare 구현의 경우, 보고서 작성을 진행할때 always taken / always not taken와 비교해야한다.**

| Test name | Gshare | Always not taken | Always taken | 
:----------:|:------:|:----------------:|:------------:|
| basic     |   35   |          35      |       35     |
| ifelse    |   43   |          43      |       51     | 
| loop      |   326  |          322     |       326    |
| non-controlflow | 46 |        46      |       46     |
| recursive |   1203 |          1187    |       1229   |

* 모든 레지스터의 값은 모두 동일하였다. 즉, Branch Prediction이 어떻든, 심지어 항상 PC를 0으로 예측하더라도 올바르게 동작한다.
* control 명령어가 없는 basic, non-controlflow 테스트는 사이클 수가 동일하였다.
* ifelse 테스트는 Always taken만 사이클 수가 높게 나왔다. 이는 Always taken 방법이 ifelse보다 반복문에 더 친숙하며, ifelse에서는 잘못된 예측이 많은 것으로 생각된다.
* loop와 recursive 테스트에서 Gshare 구현이 Always not taken보다 오히려 더 사이클 수가 증가했는데, 이는 Gshare가 처음에 초기화 된 상태로 시작하고, 분기 예측에 익숙해지기까지 시간이 부족했기 때문이라고 생각된다.

ubuntu@subvnic:~/CSED311/Lab04-2/Lab4-2$ ./convert 
Usage: ./convert [TestName or TestNumber]
TestNumber:
  0) basic
  1) ifelse
  2) loop
  3) non-controlflow
  4) recursive
ubuntu@subvnic:~/CSED311/Lab04-2/Lab4-2$ ./check
Test 0
TOTAL CYCLE : 35 (Answer : 36)
Correct output : 32/32
Test 1
TOTAL CYCLE : 43 (Answer : 44)
Correct output : 32/32
Test 2
TOTAL CYCLE : 326 (Answer : 323)
Correct output : 32/32
Test 3
TOTAL CYCLE : 46 (Answer : 46)
Correct output : 32/32
Test 4
TOTAL CYCLE : 1203 (Answer : 1188)
Correct output : 32/32

FINAL REGISTER OUTPUT
 0 00000000 (Answer : 00000000)
 1 00000000 (Answer : 00000000)
 2 00002ffc (Answer : 00002ffc)
 3 00000000 (Answer : 00000000)
 4 00000000 (Answer : 00000000)
 5 00000000 (Answer : 00000000)
 6 00000000 (Answer : 00000000)
 7 00000000 (Answer : 00000000)
 8 00000000 (Answer : 00000000)
 9 00000000 (Answer : 00000000)
10 0000000a (Answer : 0000000a)
11 0000003f (Answer : 0000003f)
12 fffffff1 (Answer : fffffff1)
13 0000002f (Answer : 0000002f)
14 0000000e (Answer : 0000000e)
15 00000021 (Answer : 00000021)
16 0000000a (Answer : 0000000a)
17 0000000a (Answer : 0000000a)
18 00000000 (Answer : 00000000)
19 00000000 (Answer : 00000000)
20 00000000 (Answer : 00000000)
21 00000000 (Answer : 00000000)
22 00000000 (Answer : 00000000)
23 00000000 (Answer : 00000000)
24 00000000 (Answer : 00000000)
25 00000000 (Answer : 00000000)
26 00000000 (Answer : 00000000)
27 00000000 (Answer : 00000000)
28 00000000 (Answer : 00000000)
29 00000000 (Answer : 00000000)
30 00000000 (Answer : 00000000)
31 00000000 (Answer : 00000000)
Correct output : 32/32