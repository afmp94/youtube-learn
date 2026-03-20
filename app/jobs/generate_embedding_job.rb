class GenerateEmbeddingJob < ApplicationJob
  queue_as :default

  def perform(record_type, record_id)
    record = record_type.constantize.find(record_id)
    generator = Embeddings::Generator.new

    text = case record
    when VideoLearning
      Embeddings::VideoLearningEmbedder.new(record).embeddable_text
    when Quote
      "#{record.speaker}: #{record.text}"
    else
      return
    end

    embedding = generator.generate(text)
    record.update_columns(embedding: embedding, embedding_generated_at: Time.current)
  end
end
