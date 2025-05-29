import json
from scoring.module import ScoreModule
from util.logging.session_logger import SessionLogger
from core.models import WidgetQset



class EnigmaGS(ScoreModule):
    def __init__(self, play_id, instance, play=None):
        super().__init__(play_id, instance, play)
        self.new_logs = {}
        self.q_ids = None
        self.scores = {}
        widget_qset = self.instance.get_latest_qset()
        decoded_data = WidgetQset.decode_data(widget_qset.data)
        self.hide_correct = decoded_data.get("options", {}).get("hide_correct", True)
        self.load_questions()
        print(f"self.questions: {self.questions}")

    def check_answer(self, log):
        item_id = str(log.item_id if hasattr(log, "item_id") else log["item_id"])
        user_text = log.text if hasattr(log, "text") else log["text"]
        question = self.questions.get(item_id)

        if not question:
            return 0

        for answer in question.get("answers", []):
            if user_text.strip() == str(answer["text"]).strip():
                return int(answer.get("value", 0))

        return 0

    def handle_log_question_answered(self, log):
        item_id = str(log.item_id if hasattr(log, "item_id") else log["item_id"])
        print(f"item_id: {item_id}")
        print(f"self.questions: {self.questions}")

        if self.q_ids is None:
            self.q_ids = list(self.questions.keys())

        self.total_questions += 1
        score = self.check_answer(log)
        self.verified_score += score
        self.scores[item_id] = score

        q_index = self.q_ids.index(item_id)
        self.new_logs[q_index] = log

    def details_for_question_answered(self, log):
        if not self.hide_correct:
            return super().details_for_question_answered(log)

        item_id = str(log.item_id if hasattr(log, "item_id") else log["item_id"])
        question = self.questions.get(item_id)
        score = self.check_answer(log)

        return {
            "data": [
                self.get_ss_question(log, question),
                self.get_ss_answer(log, question),
            ],
            "data_style": ["question", "response"],
            "score": score,
            "feedback": self.get_feedback(log, question["answers"]),
            "type": log.log_type if hasattr(log, "log_type") else log["type"],
            "style": self.get_detail_style(score),
            "tag": "div",
            "symbol": "%",
            "graphic": "score",
            "display_score": True,
        }

    def get_score_details(self):
        if not self.hide_correct:
            return super().get_score_details()

        details = []
        for log in self.logs:
            log_type = log.log_type if hasattr(log, "log_type") else log["type"]
            print(f"log_type: {log_type}")
            if log_type == "SCORE_QUESTION_ANSWERED":
                item_id = str(log.item_id if hasattr(log, "item_id") else log["item_id"])
                if item_id in self.questions:
                    details.append(self.details_for_question_answered(log))

        return [{
            "title": self._ss_table_title,
            "headers": ["Score", "The Question", "Your Response"],
            "table": details,
        }]

