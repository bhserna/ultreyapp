class CreatePreparations < ActiveRecord::Migration[8.1]
  class PreparationRecord < ActiveRecord::Base
    self.table_name = "preparations"
  end

  def up
    create_table :preparations do |t|
      t.string :title, null: false
      t.string :day, null: false
      t.string :phase, null: false, default: "program"
      t.string :start_time
      t.json :act_ids, null: false, default: []
      t.timestamps
    end

    PreparationRecord.reset_column_information
    PreparationRecord.insert_all!([
      { id: 1, title: "Actividades en la Arena previo a que llegue el desfile", day: "Domingo 15", phase: "before_parade", start_time: "Por definir con Programa", act_ids: [] },
      { id: 2, title: "Preparación para el Acto 1 y 2", day: "Domingo 15", phase: "program", start_time: "09:45", act_ids: [ 1, 2 ] },
      { id: 3, title: "Preparación para el Acto 3", day: "Domingo 15", phase: "program", start_time: "10:00", act_ids: [ 3 ] },
      { id: 4, title: "Preparación para el Acto 4", day: "Domingo 15", phase: "program", start_time: "10:20", act_ids: [ 4 ] },
      { id: 5, title: "Preparación para el Acto 5", day: "Domingo 15", phase: "program", start_time: "11:30", act_ids: [ 5 ] },
      { id: 6, title: "Preparación para el Acto 6 / Llamados a ser peregrinos de la esperanza en los ambientes", day: "Domingo 15", phase: "program", start_time: "11:40", act_ids: [ 6 ] },
      { id: 7, title: "Preparación para el Acto 7 / Comida / Bendición de alimentos / Animación", day: "Domingo 15", phase: "program", start_time: "12:30", act_ids: [ 7, 8, 9, 10 ] },
      { id: 8, title: "Preparación para el Acto 8 / Misa / Coro Jessed)", day: "Domingo 15", phase: "program", start_time: "13:00", act_ids: [ 11 ] },
      { id: 9, title: "Preparación para el Acto 9 / Vivencia 1/ Agradecimiento", day: "Domingo 15", phase: "program", start_time: "15:35", act_ids: [ 12 ] },
      { id: 10, title: "Preparación para el Acto 10 / Animación coro de Cursillos y Bendicam", day: "Domingo 15", phase: "program", start_time: "16:00", act_ids: [ 13 ] },
      { id: 11, title: "Preparación para el Acto 11 / Vivencia 2/ Agradecimiento", day: "Domingo 15", phase: "program", start_time: "16:20", act_ids: [ 14 ] },
      { id: 12, title: "Preparación para el Acto 12 / Proyección Video MCC", day: "Domingo 15", phase: "program", start_time: "16:50", act_ids: [ 15 ] },
      { id: 13, title: "Preparación para el Acto 13 / Tema 2/ Agradecimiento", day: "Domingo 15", phase: "program", start_time: "16:55", act_ids: [ 16 ] },
      { id: 14, title: "Preparación para el Acto 14 / Animación coro de Cursillos y Bendicam", day: "Domingo 15", phase: "program", start_time: "17:40", act_ids: [ 17 ] },
      { id: 15, title: "Preparación para el Acto 15 / Vivencia 3, Empresario influyendo en mi ambiente/ Agradecimiento", day: "Domingo 15", phase: "program", start_time: "18:00", act_ids: [ 18 ] },
      { id: 16, title: "Preparación para el Acto 16 / Avisos Finales", day: "Domingo 15", phase: "program", start_time: "18:25", act_ids: [ 19 ] },
      { id: 17, title: "Preparación para el lunes 16 / Acto 17", day: "Domingo 15", phase: "program", start_time: "19:00", act_ids: [ 20 ] },
      { id: 18, title: "Preparación  del Acto 17 / INICIO / Bienvenida", day: "Lunes 16", phase: "program", start_time: "07:40", act_ids: [ 20 ] },
      { id: 19, title: "Preparación  del Acto 19 / Rosario", day: "Lunes 16", phase: "program", start_time: "08:30", act_ids: [ 22 ] },
      { id: 20, title: "Preparación para el Acto 20 / Vivencia 4/ Agradecimiento", day: "Lunes 16", phase: "program", start_time: "21:30", act_ids: [ 23 ] },
      { id: 21, title: "Preparación para el Acto 21 / Tema 3/ Agradecimiento", day: "Lunes 16", phase: "program", start_time: "09:55", act_ids: [ 24 ] },
      { id: 22, title: "Preparación para el Acto 22 / Intercambio y Animación - Salvador Amor y Bendicam", day: "Lunes 16", phase: "program", start_time: "10:40", act_ids: [ 25 ] },
      { id: 23, title: "Preparación para el Acto 23 / Vivencia 5, Vocación al sacerdocio después de vivir el cursillo / Agradecimiento", day: "Lunes 16", phase: "program", start_time: "11:05", act_ids: [ 26 ] },
      { id: 24, title: "Preparación para el Acto 24 / Vivencia 6, Sacerdocio vivido a la luz del carisma de cursillos / Agradecimiento", day: "Lunes 16", phase: "program", start_time: "11:05", act_ids: [ 27 ] },
      { id: 25, title: "Preparación para el Acto 25 / Palabras del Presidente Mundial", day: "Lunes 16", phase: "program", start_time: "12:07", act_ids: [ 28 ] },
      { id: 26, title: "Preparación para el Acto 26 / Misa - Coro de Cursillos", day: "Lunes 16", phase: "program", start_time: "12:40", act_ids: [ 29 ] }
    ])

    add_foreign_key :activities, :preparations
  end

  def down
    remove_foreign_key :activities, :preparations
    drop_table :preparations
  end
end
