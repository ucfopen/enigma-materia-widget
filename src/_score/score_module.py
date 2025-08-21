import json
from scoring.module import ScoreModule
from core.models import WidgetQset



class EnigmaGS(ScoreModule):
    def __init__(self,  play):
        super().__init__(play)
        self.new_logs = {}
        self.q_ids = None
        opts = self.qset.get("options", {}) if isinstance(self.qset, dict) else {}
        self.hide_correct = opts.get("hide_correct", True)
        print("===========DEBUG WIDGET SCORE MODULE==============")
        print(f"opts: {opts}")
        print(f"self.questions: {self.questions}")
        print(f"self.hide_correct: {self.hide_correct}")


    def _ensure_q_ids(self):
        if self.q_ids is not None:
            return
        try:
            # self.questions is a QuerySet[Question]
            self.q_ids = [str(q.item_id) for q in self.questions]
        except Exception:
            self.q_ids = []


    def check_answer(self, log):
        question = self.get_question_by_item_id(log.item_id)
        if not question:
            return 0

        user_text = str(log.text).strip()
        for ans in question.get("answers", []):
            if user_text == str(ans.get("text", "")).strip():
                try:
                    return int(ans.get("value", 0))
                except Exception:
                    return 0
        return 0


    def handle_log_question_answered(self, log):
        item_id = str(log.item_id)
        print(f"item_id: {item_id}")
        print(f"self.questions: {self.questions}")

        self._ensure_q_ids()
        score = int(self.check_answer(log))
        self.scores[item_id] = score
        try:
            q_index = self.q_ids.index(item_id) if self.q_ids else None
        except ValueError:
            q_index = None
        if q_index is not None:
            self.new_logs[q_index] = log

        self.total_questions += 1


