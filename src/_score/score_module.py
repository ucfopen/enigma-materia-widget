from scoring.module import ScoreModule


class EnigmaGS(ScoreModule):

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
